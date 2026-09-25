using Government_Service_Navigator.AgenticAi.Agents.ValidationSafety;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Government_Service_Navigator.Backend.DTOs.Requests;

namespace Government_Service_Navigator.Backend.Services;

public class VerificationTaskEnqueuerService : IVerificationTaskEnqueuer
{
    private readonly IVerificationService _verificationService;

    public VerificationTaskEnqueuerService(IVerificationService verificationService)
    {
        _verificationService = verificationService;
    }

    public async Task<int> EnqueueTaskAsync(int applicationId, string citizenNic, string agentId)
    {
        var task = await _verificationService.CreateTaskAsync(new CreateTaskRequest
        {
            ApplicationId = applicationId,
            CitizenNic = citizenNic
        }, agentId);

        return task.Id;
    }
}
