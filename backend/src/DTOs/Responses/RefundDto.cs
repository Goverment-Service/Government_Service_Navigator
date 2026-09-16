namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class RefundDto
    {
        public int Id { get; set; }
        public int PaymentId { get; set; }
        public string TransactionReference { get; set; } = string.Empty;
        public string UserFullName { get; set; } = string.Empty;
        public string UserEmail { get; set; } = string.Empty;
        public decimal PaymentAmount { get; set; }
        public string Currency { get; set; } = string.Empty;

        public string Status { get; set; } = string.Empty;
        public DateTime RequestedAt { get; set; }

        public string? AccountHolderName { get; set; }
        public string? BankName { get; set; }
        public string? BranchName { get; set; }
        public string? AccountNumber { get; set; }
        public string? Reason { get; set; }
        public DateTime? FormSubmittedAt { get; set; }

        public string? ProcessedByOfficerName { get; set; }
        public DateTime? ProcessedAt { get; set; }
        public string? ProcessingNotes { get; set; }
        public decimal? RefundAmount { get; set; }
    }

    // Minimal, safe-to-expose-anonymously view used by the public refund form page.
    public class RefundFormViewDto
    {
        public string TransactionReference { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string Currency { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public bool AlreadySubmitted { get; set; }
    }
}
