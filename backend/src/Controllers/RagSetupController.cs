using AgenticAi.Agents.IntakePlanningAgent;
using Backend.Data;
using Government_Service_Navigator.AgenticAi.Agents.ActionToolAgent.Retrieval;
using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RagSetupController : ControllerBase
{
    private readonly VectorDbContext _vectorDb;
    private readonly IGenerativeAiService _aiService;
    private readonly IServiceCatalogService _catalogService;
    private readonly AppDbContext _appDb;

    public RagSetupController(
        VectorDbContext vectorDb, 
        IGenerativeAiService aiService, 
        IServiceCatalogService catalogService,
        AppDbContext appDb)
    {
        _vectorDb = vectorDb;
        _aiService = aiService;
        _catalogService = catalogService;
        _appDb = appDb;
    }

    [HttpPost("seed")]
    public async Task<IActionResult> SeedDatabase()
    {
        // 1. Wipe out the old catalog chunks (Agent 3's ActionTool:* chunks are re-seeded separately)
        _vectorDb.KnowledgeChunks.RemoveRange(
            _vectorDb.KnowledgeChunks.Where(c => !c.SourceCategory.StartsWith(ActionKnowledgeCategories.Prefix)));
        await _vectorDb.SaveChangesAsync();

        // 2. Fetch live data from your actual relational database
        var activeServices = await _catalogService.GetAllServicesAsync();
        int seededCount = 0;

        foreach (var service in activeServices)
        {
            // Fetch the full details to ensure we get the nested Documents and Fees
            var fullService = await _catalogService.GetServiceByIdAsync(service.Id);
            if (fullService == null) continue;

            // 3. Extract exact properties: DocumentName and Name
            var docText = fullService.DocumentRequirements != null && fullService.DocumentRequirements.Any()
                ? string.Join(", ", fullService.DocumentRequirements.Select(d => d.DocumentName))
                : "No specific documents required";

            var feeText = fullService.FeeSchedules != null && fullService.FeeSchedules.Any()
                ? string.Join(", ", fullService.FeeSchedules.Select(f => $"LKR {f.Amount} for {f.FeeType}"))
                : "Free of charge";

            var docChunk = $"{fullService.Name} ({fullService.Category}): To apply for this service, citizens must provide the following documents: {docText}. The applicable fees are: {feeText}.";

            // 4. Create the vector embedding and save to Neon
            var vector = await _aiService.GetEmbeddingAsync(docChunk);
            
            _vectorDb.KnowledgeChunks.Add(new KnowledgeChunk
            {
                Content = docChunk,
                SourceCategory = fullService.Category ?? "General Procedure",
                Embedding = vector
            });
            
            seededCount++;
        }

        await _vectorDb.SaveChangesAsync();
        return Ok($"Successfully synchronized {seededCount} live catalog services into the VectorDb.");
    }

    /// <summary>
    /// Vectorizes the knowledge the Action/Tool Agent (Agent 3) retrieves: per-service fee schedules,
    /// application form templates and the appointment policy. Re-running replaces only ActionTool:* chunks.
    /// </summary>
    [HttpPost("seed-action-agent")]
    public async Task<IActionResult> SeedActionAgentKnowledge()
    {
        // 1. Remove previous Agent 3 chunks only
        _vectorDb.KnowledgeChunks.RemoveRange(
            _vectorDb.KnowledgeChunks.Where(c => c.SourceCategory.StartsWith(ActionKnowledgeCategories.Prefix)));
        await _vectorDb.SaveChangesAsync();

        var chunks = new List<(string Category, string Content)>();

        // 2. Fee schedule chunks (one per service)
        var services = await _catalogService.GetAllServicesAsync();
        foreach (var service in services)
        {
            var fees = service.FeeSchedules.Any()
                ? string.Join("; ", service.FeeSchedules.Select(f =>
                    $"{f.FeeType}: LKR {f.Amount:N2}" + (f.EffectiveDate != default ? $" effective from {f.EffectiveDate:yyyy-MM-dd}" : "")))
                : "no fee is charged (free of charge)";

            chunks.Add((ActionKnowledgeCategories.Fees,
                $"Fee schedule for {service.Name} ({service.ServiceId}, {service.Category}, service procedure ID {service.Id}): {fees}. " +
                "Express, urgent or one-day fees apply only when the citizen requests faster processing."));
        }

        // 3. Application form template chunks (one per active template linked to a service)
        var templates = await _appDb.Templates
            .Include(t => t.Fields)
            .Include(t => t.ServiceProcedure)
            .Where(t => t.Status == "Active" && t.ServiceProcedureId != null)
            .ToListAsync();

        foreach (var template in templates)
        {
            var fieldText = template.Fields.Any()
                ? string.Join("; ", template.Fields.OrderBy(f => f.OrderIndex).Select(f =>
                    $"{f.Label} ({f.Type}{(f.IsRequired ? ", required" : ", optional")}{(string.IsNullOrWhiteSpace(f.Options) ? "" : $", options: {f.Options}")})"))
                : "no fields defined";

            chunks.Add((ActionKnowledgeCategories.FormTemplate,
                $"Application form '{template.FormName}' for {template.ServiceProcedure?.Name ?? "service"} (service procedure ID {template.ServiceProcedureId}). " +
                $"Fields: {fieldText}." + (string.IsNullOrWhiteSpace(template.LawText) ? "" : $" Legal basis: {template.LawText}")));
        }

        // 4. Appointment policy chunk (mirrors FindAppointmentSlotTool)
        chunks.Add((ActionKnowledgeCategories.AppointmentPolicy,
            "Appointment policy: counter appointments are offered Monday to Friday between 09:00 and 15:00 Sri Lanka Time in 30-minute slots, " +
            "at least 2 working days after the draft is prepared. A proposed slot is only reserved after a Verifying Officer approves the application."));

        // 5. Embed and store in the vector DB
        foreach (var (category, content) in chunks)
        {
            var vector = await _aiService.GetEmbeddingAsync(content);
            _vectorDb.KnowledgeChunks.Add(new KnowledgeChunk
            {
                Content = content,
                SourceCategory = category,
                Embedding = vector
            });
        }

        await _vectorDb.SaveChangesAsync();
        return Ok($"Vectorized {chunks.Count} Action/Tool Agent knowledge chunks into the VectorDb.");
    }
}
