namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class PaymentDto
    {
        public int Id { get; set; }
        public string TransactionReference { get; set; } = string.Empty;

        public int UserId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public string UserEmail { get; set; } = string.Empty;

        public string? ApplicationId { get; set; }
        public string ServiceName { get; set; } = string.Empty;

        public string Method { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string Currency { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;

        public string? BankName { get; set; }
        public string? BranchName { get; set; }
        public string? AccountNumber { get; set; }
        public string? ReferenceNumber { get; set; }
        public DateTime? PaymentDate { get; set; }
        public string? SlipFileName { get; set; }
        public DateTime? SlipUploadedAt { get; set; }
        public bool HasSlip { get; set; }

        public string? StripePaymentIntentId { get; set; }
        public string? StripeReceiptUrl { get; set; }

        public string? VerifiedByOfficerName { get; set; }
        public DateTime? VerifiedAt { get; set; }
        public string? VerificationNotes { get; set; }

        public DateTime CreatedAt { get; set; }

        public bool RefundEligible { get; set; }
        public RefundDto? Refund { get; set; }
    }
}
