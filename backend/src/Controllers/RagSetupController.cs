using AgenticAi.Agents.IntakePlanningAgent;
using Backend.Data;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Government_Service_Navigator.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RagSetupController : ControllerBase
{
    private readonly VectorDbContext _vectorDb;
    private readonly IGenerativeAiService _aiService;
    private readonly IServiceCatalogService _catalogService;

    public RagSetupController(
        VectorDbContext vectorDb, 
        IGenerativeAiService aiService, 
        IServiceCatalogService catalogService)
    {
        _vectorDb = vectorDb;
        _aiService = aiService;
        _catalogService = catalogService;
    }

    [HttpPost("seed")]
    public async Task<IActionResult> SeedDatabase()
    {
        // 1. Wipe out the old hardcoded dummy data
        _vectorDb.KnowledgeChunks.RemoveRange(_vectorDb.KnowledgeChunks);
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
}
