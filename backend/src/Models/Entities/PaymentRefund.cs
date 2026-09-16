using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    // Tracks a refund request end-to-end: the citizen's initial request,
    // the emailed form they fill in with their refund bank details, and the
    // Finance Officer's decision.
    public class PaymentRefund
    {
        public int Id { get; set; }

        public int PaymentId { get; set; }
        public Payment? Payment { get; set; }

        // Requested -> FormSubmitted -> Approved | Rejected
        public string Status { get; set; } = "Requested";

        public string RequestToken { get; set; } = string.Empty;
        public DateTime RequestedAt { get; set; } = DateTime.UtcNow;
        public DateTime? RequestEmailSentAt { get; set; }

        // Citizen-submitted refund form
        public string? AccountHolderName { get; set; }
        public string? BankName { get; set; }
        public string? BranchName { get; set; }
        public string? AccountNumber { get; set; }
        public string? Reason { get; set; }
        public DateTime? FormSubmittedAt { get; set; }

        // Finance Officer processing
        public int? ProcessedByOfficerId { get; set; }
        public string? ProcessedByOfficerName { get; set; }
        public DateTime? ProcessedAt { get; set; }
        public string? ProcessingNotes { get; set; }
        public decimal? RefundAmount { get; set; }
        public string? StripeRefundId { get; set; }
    }
}
