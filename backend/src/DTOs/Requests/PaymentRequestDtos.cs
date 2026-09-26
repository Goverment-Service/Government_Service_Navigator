namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class CreateManualPaymentDto
    {
        public int ApplicationId { get; set; }
        public decimal Amount { get; set; }
        public string UserEmail { get; set; } = string.Empty;
        public string ManualSlipUrl { get; set; } = string.Empty;
    }

    public class VerifyManualPaymentDto
    {
        // true = mark Paid, false = mark Failed/Rejected
        public bool Approved { get; set; }
        public string? Note { get; set; }
    }

    public class CreateCheckoutSessionDto
    {
        public int ApplicationId { get; set; }
        public decimal Amount { get; set; }
        public string UserEmail { get; set; } = string.Empty;
    }

    public class UpdatePaymentStatusDto
    {
        public string Status { get; set; } = string.Empty; // "Paid", "Verified", "Failed", "Rejected", "Pending", "PendingVerification"
        public string? Note { get; set; }
    }
}