using System;
using System.Collections.Generic;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class InstallmentPlan
    {
        public int Id { get; set; }

        public int PaymentId { get; set; }
        public Payment? Payment { get; set; }

        public int NumberOfInstallments { get; set; }
        public decimal TotalAmount { get; set; }

        // "Active", "Completed", "Cancelled"
        public string Status { get; set; } = "Active";

        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

        public ICollection<Installment>? Installments { get; set; }
    }
}