using System.Text.Json;
using Government_Service_Navigator.AgenticAi.Tools.GetDocumentRequirements;
using Government_Service_Navigator.AgenticAi.Tools.CalculateFee;
using Government_Service_Navigator.AgenticAi.Tools.PrefillApplication;
using Government_Service_Navigator.Backend.Data.Context;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services;

public class FeeScheduleRepository : IFeeScheduleRepository
{
    private readonly AppDbContext _db;

    public FeeScheduleRepository(AppDbContext db)
    {
        _db = db;
    }

    public async Task<List<FeeScheduleEntry>> GetFeeSchedulesAsync(int serviceProcedureId, int? stage = null, CancellationToken cancellationToken = default)
    {
        if (stage.HasValue && stage.Value > 0)
        {
            var stageTemplate = await _db.Templates
                .Include(t => t.Fields)
                .Where(t => t.ServiceProcedureId == serviceProcedureId && t.StageOrder == stage.Value && t.Status == "Active")
                .OrderByDescending(t => t.CreatedAt)
                .FirstOrDefaultAsync(cancellationToken);

            if (stageTemplate != null)
            {
                var paymentField = stageTemplate.Fields.FirstOrDefault(f => f.Type == "payment");
                if (paymentField != null && !string.IsNullOrWhiteSpace(paymentField.Options))
                {
                    try
                    {
                        using var pDoc = JsonDocument.Parse(paymentField.Options);
                        if (pDoc.RootElement.TryGetProperty("amount", out var amt) && amt.GetDecimal() > 0)
                        {
                            var stageAmt = amt.GetDecimal();
                            string feeName = pDoc.RootElement.TryGetProperty("feeType", out var ft) && ft.GetString() is string s && !string.IsNullOrWhiteSpace(s)
                                ? s
                                : paymentField.Label;
                            return new List<FeeScheduleEntry> { new(feeName, stageAmt, DateTime.UtcNow) };
                        }
                    }
                    catch { }
                }

                // If this stage template exists and has no payment field, then no fee is charged for this stage
                return new List<FeeScheduleEntry>();
            }
        }

        return await _db.FeeSchedules
            .Where(f => f.ServiceProcedureId == serviceProcedureId)
            .Select(f => new FeeScheduleEntry(f.FeeType, f.Amount, f.EffectiveDate))
            .ToListAsync(cancellationToken);
    }
}

public class ApplicationTemplateRepository : IApplicationTemplateRepository
{
    private readonly AppDbContext _db;

    public ApplicationTemplateRepository(AppDbContext db)
    {
        _db = db;
    }

    public async Task<List<FormFieldDefinition>> GetFormFieldsAsync(int serviceProcedureId, int? stage = null, CancellationToken cancellationToken = default)
    {
        var query = _db.Templates
            .Include(t => t.Fields)
            .Where(t => t.ServiceProcedureId == serviceProcedureId && t.Status == "Active");

        if (stage.HasValue && stage.Value > 0)
        {
            query = query.Where(t => t.StageOrder == stage.Value);
        }

        var template = await query
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (template == null) return new List<FormFieldDefinition>();

        return template.Fields
            .OrderBy(f => f.OrderIndex)
            .Select(f => new FormFieldDefinition(f.Label, f.Type, f.IsRequired, f.OrderIndex))
            .ToList();
    }
}

public class DocumentRequirementRepository : IDocumentRequirementRepository
{
    private readonly AppDbContext _db;

    public DocumentRequirementRepository(AppDbContext db)
    {
        _db = db;
    }

    public async Task<List<string>> GetDocumentNamesAsync(int serviceProcedureId, int? stage = null, CancellationToken cancellationToken = default)
    {
        if (stage.HasValue && stage.Value > 0)
        {
            var stageTemplate = await _db.Templates
                .Include(t => t.Fields)
                .Where(t => t.ServiceProcedureId == serviceProcedureId && t.StageOrder == stage.Value && t.Status == "Active")
                .OrderByDescending(t => t.CreatedAt)
                .FirstOrDefaultAsync(cancellationToken);

            if (stageTemplate != null)
            {
                var fileFields = stageTemplate.Fields
                    .Where(f => f.Type == "file" || f.Type == "document" || f.Type == "documentUpload")
                    .Select(f => f.Label.Trim().TrimEnd(':').Trim())
                    .Where(l => !string.IsNullOrWhiteSpace(l))
                    .Distinct()
                    .ToList();

                if (fileFields.Count > 0)
                {
                    return fileFields;
                }
            }
        }

        return await _db.DocumentRequirements
            .Where(d => d.ServiceProcedureId == serviceProcedureId)
            .OrderBy(d => d.Id)
            .Select(d => d.DocumentName)
            .ToListAsync(cancellationToken);
    }
}
