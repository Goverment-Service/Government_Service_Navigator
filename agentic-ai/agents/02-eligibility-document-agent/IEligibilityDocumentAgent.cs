using System.Threading;
using System.Threading.Tasks;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.DTOs;

namespace Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent;

public interface IEligibilityDocumentAgent
{
    Task<EligibilityPlanResponse> EvaluateEligibilityAsync(
        EligibilityPlanRequest request, 
        CancellationToken cancellationToken = default);
}
