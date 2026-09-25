using System.Threading.Tasks;

namespace Government_Service_Navigator.AgenticAi.Agents.ValidationSafety
{
    public interface IVerificationTaskEnqueuer
    {
        Task<int> EnqueueTaskAsync(int applicationId, string citizenNic, string agentId);
    }
}
