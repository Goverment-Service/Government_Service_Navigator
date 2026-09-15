using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IVerificationService
    {
        Task<VerificationTask> CreateTaskAsync(CreateTaskRequest request, string agentId);
        Task<bool> RecordDecisionAsync(int taskId, VerificationDecisionRequest request, string officerId);
        Task<bool> DeleteTaskAsync(int taskId, string officerId);
        Task<bool> BulkVerifyAsync(BulkVerifyRequest request, string officerId);
        Task<List<AuditLog>> GetAuditLogsAsync(int applicationId);
        Task<List<AuditLog>> GetAllAuditLogsAsync();
        Task<List<VerificationTask>> GetPendingTasksAsync();
        Task<OfficerStatsDto> GetOfficerStatsAsync(string officerId);
    }
}
