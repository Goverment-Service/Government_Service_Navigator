using System.Collections.Generic;

namespace Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.DTOs;

public record EligibilityPlanResponse(
    bool IsEligible,
    int MatchPercentage,
    List<string> MissingCriteria,
    List<string> RequiredDocuments,
    List<string> MissingDocuments,
    string Reasoning,
    List<string> RetrievedContextSnippets
);
