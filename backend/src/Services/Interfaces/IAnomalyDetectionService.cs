using Government_Service_Navigator.Backend.Models.Entities;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IAnomalyDetectionService
    {
        Task<List<AnomalyFlag>> ScanAsync();
        Task<List<AnomalyFlag>> GetOpenFlagsAsync();
        Task<AnomalyFlag> ResolveFlagAsync(int id, string status, string reviewedByEmail);
    }
}