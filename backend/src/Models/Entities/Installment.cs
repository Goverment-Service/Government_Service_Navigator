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

        // "Pending", "Paid", "Overdue"
        public string Status { get; set; } = "Pending";

        public DateTime? PaidDate { get; set; }
    }
}