using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class InstallmentScheduleItem
    {
        public int Id { get; set; }
        public int InstallmentPlanId { get; set; }
        public int InstallmentNumber { get; set; }
        public decimal AmountDue { get; set; }
        public decimal AmountPaid { get; set; } = 0;
        public DateTime DueDate { get; set; }
        public InstallmentStatus Status { get; set; } = InstallmentStatus.Upcoming;
    }
}
