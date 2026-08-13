using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class InstallmentPlan
    {
        public int Id { get; set; }
        public int PaymentId { get; set; }
        public decimal TotalAmount { get; set; }
        public int NumberOfInstallments { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
