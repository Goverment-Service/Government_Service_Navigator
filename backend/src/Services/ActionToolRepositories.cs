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

    public async Task<List<FeeScheduleEntry>> GetFeeSchedulesAsync(int serviceProcedureId, CancellationToken cancellationToken = default)
    {
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

    public async Task<List<FormFieldDefinition>> GetFormFieldsAsync(int serviceProcedureId, CancellationToken cancellationToken = default)
    {
        var template = await _db.Templates
            .Include(t => t.Fields)
            .Where(t => t.ServiceProcedureId == serviceProcedureId && t.Status == "Active")
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

    public async Task<List<string>> GetDocumentNamesAsync(int serviceProcedureId, CancellationToken cancellationToken = default)
    {
        return await _db.DocumentRequirements
            .Where(d => d.ServiceProcedureId == serviceProcedureId)
            .OrderBy(d => d.Id)
            .Select(d => d.DocumentName)
            .ToListAsync(cancellationToken);
    }
}
