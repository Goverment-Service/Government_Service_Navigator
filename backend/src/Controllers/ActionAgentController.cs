using Government_Service_Navigator.AgenticAi.Agents.ActionToolAgent;
using Government_Service_Navigator.AgenticAi.Agents.ActionToolAgent.DTOs;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.DTOs;
using Government_Service_Navigator.AgenticAi.Orchestration;
using Government_Service_Navigator.AgenticAi.State;
using Government_Service_Navigator.AgenticAi.Tools.PrefillApplication;
using Microsoft.AspNetCore.Mvc;

namespace Government_Service_Navigator.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ActionAgentController : ControllerBase
{
    private readonly IActionToolAgent _actionAgent;
    private readonly IAgent3WorkflowOrchestrator _orchestrator;
    private readonly IEligibilityDocumentAgent _eligibilityAgent;

    public ActionAgentController(
        IActionToolAgent actionAgent,
        IAgent3WorkflowOrchestrator orchestrator,
        IEligibilityDocumentAgent eligibilityAgent)
    {
        _actionAgent = actionAgent;
        _orchestrator = orchestrator;
        _eligibilityAgent = eligibilityAgent;
    }

    /// <summary>
    /// Prepares a draft application (pre-filled form, fee, proposed appointment) using the
    /// Action/Tool Agent. If no eligibility result is supplied, Agent 2 is run first.
    /// </summary>
    [HttpPost("draft")]
    public async Task<IActionResult> PrepareDraft([FromBody] ActionAgentQueryDto query)
    {
        if (query.ServiceProcedureId <= 0 || string.IsNullOrWhiteSpace(query.ServiceName))
            return BadRequest("ServiceProcedureId and ServiceName are required.");

        try
        {
            var request = await BuildRequestAsync(query);
            var response = await _actionAgent.PrepareDraftAsync(request);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Draft preparation failed", details = ex.Message });
        }
    }

    /// <summary>
    /// Executes the Agent 3 stage in the Workflow Orchestrator pipeline and returns state
    /// </summary>
    [HttpPost("orchestrate")]
    public async Task<IActionResult> OrchestrateDraft([FromBody] ActionAgentQueryDto query)
    {
        if (query.ServiceProcedureId <= 0 || string.IsNullOrWhiteSpace(query.ServiceName))
            return BadRequest("ServiceProcedureId and ServiceName are required.");

        var request = await BuildRequestAsync(query);

        var state = WorkflowExecutionState.Create(
            applicationId: request.ApplicationId,
            citizenNic: request.Applicant.CitizenNic,
            serviceName: request.ServiceName);
        state.EligibilityResult = request.Eligibility;

        var updatedState = await _orchestrator.ExecuteDraftingStageAsync(state, request);
        return Ok(updatedState);
    }

    private async Task<ActionDraftRequest> BuildRequestAsync(ActionAgentQueryDto query)
    {
        var providedDocuments = query.ProvidedDocuments ?? new List<string>();

        var eligibility = query.Eligibility;
        if (eligibility == null)
        {
            var profile = new CitizenProfile
            {
                Age = query.Age,
                CitizenshipStatus = query.CitizenshipStatus,
                AnnualIncome = query.AnnualIncome,
                EmploymentStatus = query.EmploymentStatus,
                ProvidedDocuments = providedDocuments,
                AdditionalAttributes = query.AdditionalAttributes ?? new Dictionary<string, string>()
            };

            eligibility = await _eligibilityAgent.EvaluateEligibilityAsync(
                new EligibilityPlanRequest(query.ServiceName, query.ServiceProcedureId, profile, query.PlanSummary, query.Stage));
        }

        return new ActionDraftRequest(
            ApplicationId: query.ApplicationId,
            ServiceProcedureId: query.ServiceProcedureId,
            ServiceName: query.ServiceName,
            Applicant: new ApplicantDetails
            {
                CitizenNic = query.CitizenNic,
                FullName = query.FullName,
                Email = query.Email,
                Age = query.Age,
                CitizenshipStatus = query.CitizenshipStatus,
                AnnualIncome = query.AnnualIncome,
                EmploymentStatus = query.EmploymentStatus,
                AdditionalAttributes = query.AdditionalAttributes ?? new Dictionary<string, string>()
            },
            Eligibility: eligibility,
            ProvidedDocuments: providedDocuments,
            PreferredAppointmentDateUtc: query.PreferredAppointmentDateUtc,
            ExpressProcessing: query.ExpressProcessing,
            Stage: query.Stage);
    }
}

public class ActionAgentQueryDto
{
    public int ApplicationId { get; set; }
    public int ServiceProcedureId { get; set; }
    public string ServiceName { get; set; } = string.Empty;
    public string CitizenNic { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public int Age { get; set; }
    public string CitizenshipStatus { get; set; } = "Sri Lankan";
    public decimal AnnualIncome { get; set; }
    public string EmploymentStatus { get; set; } = string.Empty;
    public List<string>? ProvidedDocuments { get; set; } = new();
    public Dictionary<string, string>? AdditionalAttributes { get; set; } = new();
    public DateTime? PreferredAppointmentDateUtc { get; set; }
    public bool ExpressProcessing { get; set; }
    public string? PlanSummary { get; set; }
    public int? Stage { get; set; }

    /// <summary>Optional Agent 2 output; when omitted, Agent 2 is invoked first.</summary>
    public EligibilityPlanResponse? Eligibility { get; set; }
}
