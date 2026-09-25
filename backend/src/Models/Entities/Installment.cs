using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class Installment
    {
        public int Id { get; set; }

        public int InstallmentPlanId { get; set; }
        public InstallmentPlan? InstallmentPlan { get; set; }

        public int InstallmentNumber { get; set; }
        public decimal Amount { get; set; }
        public DateTime DueDate { get; set; }

        // "Pending", "PendingVerification" (bank transfer receipt awaiting staff review), "Paid", "Overdue"
        public string Status { get; set; } = "Pending";

        public DateTime? PaidDate { get; set; }

        // How the citizen paid it: "Online" (Stripe checkout) or "BankTransfer" (uploaded receipt)
        public string? PaymentMethod { get; set; }

        // Stripe Checkout session for an online payment
        public string? StripeSessionId { get; set; }

        // Bank transfer receipt (PaymentReceipt.Id); the file itself is stored separately
        public Guid? ReceiptId { get; set; }

        // When the due-date reminder was sent (InstallmentMonitorService), so it is only sent once
        public DateTime? ReminderSentAt { get; set; }
    }
}
