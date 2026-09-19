namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class CreateInstallmentPlanDto
    {
        public int PaymentId { get; set; }
        public int NumberOfInstallments { get; set; }

        // Days between each installment's due date (e.g. 30 for monthly).
        public int IntervalDays { get; set; } = 30;
    }

    public class MarkInstallmentPaidDto
    {
        public int InstallmentId { get; set; }
    }
}