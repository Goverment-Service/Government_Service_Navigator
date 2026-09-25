using System.Collections.Generic;
using System.Threading.Tasks;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.DTOs;
using Government_Service_Navigator.AgenticAi.Orchestration;
using Government_Service_Navigator.AgenticAi.State;
using Microsoft.AspNetCore.Mvc;

namespace Government_Service_Navigator.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EligibilityAgentController : ControllerBase
{
    private readonly IEligibilityDocumentAgent _eligibilityAgent;
    private readonly IAgent2WorkflowOrchestrator _orchestrator;

    public EligibilityAgentController(
        IEligibilityDocumentAgent eligibilityAgent,
        IAgent2WorkflowOrchestrator orchestrator)
    {
        _eligibilityAgent = eligibilityAgent;
        _orchestrator = orchestrator;
    }

    /// <summary>
    /// Evaluates citizen eligibility and missing document checklist using Gemini RAG and Vector DB
    /// </summary>
    [HttpPost("evaluate")]
    public async Task<IActionResult> EvaluateEligibility([FromBody] EligibilityAgentQueryDto query)
    {
        if (string.IsNullOrWhiteSpace(query.ServiceName))
            return BadRequest("ServiceName is required.");

        var profile = new CitizenProfile
        {
            Age = query.Age > 0 ? query.Age : 25,
            CitizenshipStatus = string.IsNullOrWhiteSpace(query.CitizenshipStatus) ? "Sri Lankan" : query.CitizenshipStatus,
            AnnualIncome = query.AnnualIncome,
            EmploymentStatus = string.IsNullOrWhiteSpace(query.EmploymentStatus) ? "Employed" : query.EmploymentStatus,
            ProvidedDocuments = query.ProvidedDocuments ?? new List<string>()
        };

        var request = new EligibilityPlanRequest(
            ServiceName: query.ServiceName,
            ServiceId: query.ServiceId,
            Profile: profile,
            PlanSummary: query.PlanSummary
        );

        try
        {
            var response = await _eligibilityAgent.EvaluateEligibilityAsync(request);
            return Ok(response);
        }
        catch (System.Exception ex)
        {
            return StatusCode(500, new { message = "Eligibility evaluation failed", details = ex.Message });
        }
    }

    /// <summary>
    /// Executes Agent 2 stage in the Workflow Orchestrator pipeline and returns state
    /// </summary>
    [HttpPost("orchestrate")]
    public async Task<IActionResult> OrchestrateEligibility([FromBody] EligibilityAgentQueryDto query)
    {
        var profile = new CitizenProfile
        {
            Age = query.Age > 0 ? query.Age : 25,
            CitizenshipStatus = string.IsNullOrWhiteSpace(query.CitizenshipStatus) ? "Sri Lankan" : query.CitizenshipStatus,
            AnnualIncome = query.AnnualIncome,
            EmploymentStatus = string.IsNullOrWhiteSpace(query.EmploymentStatus) ? "Employed" : query.EmploymentStatus,
            ProvidedDocuments = query.ProvidedDocuments ?? new List<string>()
        };

        var request = new EligibilityPlanRequest(
            ServiceName: query.ServiceName ?? "General Government Service",
            ServiceId: query.ServiceId,
            Profile: profile,
            PlanSummary: query.PlanSummary
        );

        var initialState = WorkflowExecutionState.Create(
            applicationId: query.ApplicationId > 0 ? query.ApplicationId : 1001,
            citizenNic: query.CitizenNic ?? "199512345678",
            serviceName: request.ServiceName
        );

        var updatedState = await _orchestrator.ExecuteEligibilityStageAsync(initialState, request);
        return Ok(updatedState);
    }
}

public class EligibilityAgentQueryDto
{
    public string ServiceName { get; set; } = string.Empty;
    public int? ServiceId { get; set; }
    public int Age { get; set; } = 25;
    public string CitizenshipStatus { get; set; } = "Sri Lankan";
    public decimal AnnualIncome { get; set; } = 0;
    public string EmploymentStatus { get; set; } = "Employed";
    public List<string>? ProvidedDocuments { get; set; } = new();
    public string? PlanSummary { get; set; }
    public int ApplicationId { get; set; }
    public string? CitizenNic { get; set; }
}
