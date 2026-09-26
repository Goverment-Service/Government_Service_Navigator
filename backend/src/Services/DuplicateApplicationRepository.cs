using Government_Service_Navigator.AgenticAi.Tools.CheckDuplicateApplication;
using Government_Service_Navigator.Backend.Data.Context;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services;

public class DuplicateApplicationRepository : IDuplicateApplicationRepository
{
    private readonly AppDbContext _db;

    public DuplicateApplicationRepository(AppDbContext db)
    {
        _db = db;
    }

    public async Task<bool> HasDuplicateAsync(string citizenNic, int serviceProcedureId)
    {
        if (string.IsNullOrWhiteSpace(citizenNic)) return false;
        var normalizedNic = citizenNic.Trim();
        return await _db.ApplicationSubmissions.AnyAsync(s => 
            s.CitizenNic == normalizedNic && 
            s.ServiceProcedureId == serviceProcedureId && 
            s.StageStatus != "Completed" && 
            s.StageStatus != "Rejected");
    }
}
