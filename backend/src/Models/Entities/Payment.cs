using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    // A single fee payment, made either by bank transfer/deposit (manually
    // verified by a Finance Officer from an uploaded slip) or online via
    // Stripe (confirmed automatically once Stripe reports success).
    public class Payment
    {
        public int Id { get; set; }
        public string TransactionReference { get; set; } = string.Empty;

        public int UserId { get; set; }
        public User? User { get; set; }

        public string? ApplicationId { get; set; }
        public string ServiceName { get; set; } = string.Empty;

        public string Method { get; set; } = string.Empty; // "BankTransfer" | "Stripe"
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "USD";

        // Pending, Paid, Verified, Rejected, Failed, Refunded, PartiallyRefunded
        public string Status { get; set; } = "Pending";

        // Bank transfer / deposit details
        public string? BankName { get; set; }
        public string? BranchName { get; set; }
        public string? AccountNumber { get; set; }
        public string? ReferenceNumber { get; set; }
        public DateTime? PaymentDate { get; set; }
        public string? SlipFilePath { get; set; }
        public string? SlipFileName { get; set; }
        public DateTime? SlipUploadedAt { get; set; }

        // Stripe details
        public string? StripePaymentIntentId { get; set; }
        public string? StripeChargeId { get; set; }
        public string? StripeReceiptUrl { get; set; }

        // Verification / confirmation - the moment this payment became
        // recognized revenue, used as the anchor for the 3-day refund window.
        public int? VerifiedByOfficerId { get; set; }
        public string? VerifiedByOfficerName { get; set; }
        public DateTime? VerifiedAt { get; set; }
        public string? VerificationNotes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public PaymentRefund? Refund { get; set; }
    }
}
