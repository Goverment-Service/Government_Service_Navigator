using System;
using System.Collections.Generic;

namespace Government_Service_Navigator.AgenticAi.Schemas
{
    public class ValidationResult
    {
        public bool IsValid { get; set; }
        public string Decision { get; set; } = string.Empty; // "EnqueuedForOfficer" or "Rejected"
        public string Summary { get; set; } = string.Empty;
        public List<ComplianceCheckItem> ComplianceChecks { get; set; } = new();
        public List<string> RejectionReasons { get; set; } = new();
        public int? VerificationTaskId { get; set; }
        public DateTime ProcessedAt { get; set; } = DateTime.UtcNow;

        public static ValidationResult Success(int verificationTaskId, List<ComplianceCheckItem> checks, string summary = "Deterministic schema & safety checks passed. Enqueued for Verifying Officer review.")
        {
            return new ValidationResult
            {
                IsValid = true,
                Decision = "EnqueuedForOfficer",
                Summary = summary,
                ComplianceChecks = checks,
                VerificationTaskId = verificationTaskId,
                ProcessedAt = DateTime.UtcNow
            };
        }

        public static ValidationResult Rejected(List<string> reasons, List<ComplianceCheckItem> checks, string summary = "Application failed deterministic validation checks and was halted before reaching officer queue.")
        {
            return new ValidationResult
            {
                IsValid = false,
                Decision = "Rejected",
                Summary = summary,
                ComplianceChecks = checks,
                RejectionReasons = reasons,
                VerificationTaskId = null,
                ProcessedAt = DateTime.UtcNow
            };
        }
    }
}
