using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    // A citizen's submitted application form. Its Id is the ApplicationId used by VerificationTask.
    public class ApplicationSubmission
    {
        public int Id { get; set; }
        public int ServiceProcedureId { get; set; }
        public ServiceProcedure? ServiceProcedure { get; set; }
        public Guid? TemplateId { get; set; }

        public string CitizenNic { get; set; } = string.Empty;
        public string UserEmail { get; set; } = string.Empty;

        // Answers keyed by FormField label, stored as a JSON object.
        public string FormDataJson { get; set; } = "{}";

        public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;

        public int CurrentStage { get; set; } = 1;
        public int MaxStages { get; set; } = 1;
        public string StageStatus { get; set; } = "PendingReview"; // "PendingReview", "StageApproved", "Completed", "ActionRequired"

    }
}
