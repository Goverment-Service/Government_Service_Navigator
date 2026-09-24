namespace AgenticAi.Agents.IntakePlanningAgent;

public record IntakePlanRequest(string UserNeedDescription, string? CitizenProfileId = null);

public record IntakePlanResponse(
    string RecommendedService,
    List<string> RequiredDocuments,
    List<string> StepByStepPlan,
    List<string> RetrievedContextSnippets
);

public interface IIntakePlanningAgent
{
    Task<IntakePlanResponse> GeneratePlanAsync(IntakePlanRequest request, CancellationToken cancellationToken = default);
}
