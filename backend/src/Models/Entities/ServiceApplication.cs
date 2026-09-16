using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    // A citizen's submission against a ServiceProcedure. Review/decision state
    // isn't duplicated here - it lives on the VerificationTask created at
    // submission time (VerificationTask.ApplicationId == this.Id), the same
    // review queue Officers already work from.
    public class ServiceApplication
    {
        public int Id { get; set; }
        public string ApplicationReference { get; set; } = string.Empty;

        public int UserId { get; set; }
        public User? User { get; set; }

        public int ServiceProcedureId { get; set; }
        public ServiceProcedure? ServiceProcedure { get; set; }

        // The citizen's answers to the service's Template form fields, as a
        // JSON object keyed by FormField.Id. Kept as a JSON blob rather than
        // a normalized answers table since fields are dynamic per template.
        public string AnswersJson { get; set; } = "{}";

        public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;
    }
}
