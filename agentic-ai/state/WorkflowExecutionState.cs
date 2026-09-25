using System;
using Government_Service_Navigator.AgenticAi.Schemas;

namespace Government_Service_Navigator.AgenticAi.State
{
    public class WorkflowExecutionState
    {
        public string WorkflowId { get; set; } = Guid.NewGuid().ToString("N");
        public int ApplicationId { get; set; }
        public string CitizenNic { get; set; } = string.Empty;
        public string ServiceName { get; set; } = string.Empty;

        /// <summary>
        /// Pipeline Stages: "Intake", "Eligibility", "Drafting", "ValidationAndSafety", 
        /// "PendingHumanApproval", "ApprovedByOfficer", "Rejected"
        /// </summary>
        public string CurrentStage { get; set; } = "ValidationAndSafety";

        /// <summary>
        /// Tracks human officer review status (§2 human approval gateway).
        /// Options: "NotReady", "AwaitingOfficerReview", "Approved", "Rejected", "Revised"
        /// </summary>
        public string HumanApprovalStatus { get; set; } = "NotReady";

        /// <summary>
        /// Output produced by Agent 4 (Validation & Safety Agent).
        /// </summary>
        public ValidationResult? ValidationResult { get; set; }

        /// <summary>
        /// Output produced by Agent 2 (Eligibility & Document Analysis Agent).
        /// </summary>
        public Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.DTOs.EligibilityPlanResponse? EligibilityResult { get; set; }

        /// <summary>
        /// Output produced by Agent 3 (Action/Tool Agent), including its tool call log.
        /// </summary>
        public Government_Service_Navigator.AgenticAi.Agents.ActionToolAgent.DTOs.ActionDraftResponse? ActionResult { get; set; }

        /// <summary>
        /// Draft application handed from Agent 3 to Agent 4.
        /// </summary>
        public DraftApplication? DraftApplication { get; set; }


        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public static WorkflowExecutionState Create(int applicationId, string citizenNic, string serviceName)
        {
            return new WorkflowExecutionState
            {
                ApplicationId = applicationId,
                CitizenNic = citizenNic,
                ServiceName = serviceName,
                CurrentStage = "ValidationAndSafety",
                HumanApprovalStatus = "NotReady"
            };
        }
    }
}
