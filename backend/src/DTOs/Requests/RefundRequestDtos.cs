namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class CreateRefundRequestDto
    {
        public int PaymentId { get; set; }
        public decimal RefundAmount { get; set; }
        public string Reason { get; set; } = string.Empty;
    }

    public class RefundDecisionDto
    {
        // Note appended by the officer approving/rejecting (optional).
        public string? Note { get; set; }
    }

    public class RefundProcessDto
    {
        // Manual reference e.g. bank reverse-transfer confirmation number.
        public string TransactionRef { get; set; } = string.Empty;
    }
}