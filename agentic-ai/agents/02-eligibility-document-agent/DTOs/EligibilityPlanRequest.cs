using System.Collections.Generic;

namespace Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.DTOs;

public record EligibilityPlanRequest(
    string ServiceName,
    int? ServiceId,
    CitizenProfile Profile,
    string? PlanSummary = null,
    int? Stage = null
);
