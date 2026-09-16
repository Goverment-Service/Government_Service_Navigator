using System;
using System.Collections.Generic;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class Payment
    {
        public int Id { get; set; }

        // Links back to the citizen's application (Member B's domain).
        public int ApplicationId { get; set; }

        public decimal Amount { get; set; }
        public string Currency { get; set; } = "LKR";

        // "Online" (Stripe) or "Manual" (bank transfer / cash deposit slip)
        public string Method { get; set; } = "Online";

        // "Pending", "PendingVerification", "Paid", "Failed"
        public string Status { get; set; } = "Pending";

        // Stripe payment intent / session id for online payments. Null for manual.
        public string? StripePaymentIntentId { get; set; }

        // Path/URL to the uploaded slip image/PDF for manual payments.
        public string? ManualSlipUrl { get; set; }

        // Email of the user this payment belongs to, used for SMTP receipts/notifications.
        public string UserEmail { get; set; } = string.Empty;

        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
        public DateTime? PaidDate { get; set; }

        public ICollection<RefundRequest>? RefundRequests { get; set; }
    }
}