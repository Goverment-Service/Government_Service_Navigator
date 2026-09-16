using System;
using System.Collections.Generic;

namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class ApplicationDto
    {
        public int Id { get; set; }
        public string ApplicationReference { get; set; } = string.Empty;

        public int ServiceProcedureId { get; set; }
        public string ServiceName { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;

        // Mirrors the linked VerificationTask's status: Pending, Approved, Rejected, Revised.
        public string Status { get; set; } = "Pending";

        public DateTime SubmittedAt { get; set; }
        public DateTime? DecisionAt { get; set; }
        public string? DecisionNotes { get; set; }

        public Dictionary<string, string> Answers { get; set; } = new();
    }
}
