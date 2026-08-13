using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class Payment
    {
        public int Id { get; set; }
        public int ApplicationId { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "LKR";
        public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
        public string? StripePaymentIntentId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
