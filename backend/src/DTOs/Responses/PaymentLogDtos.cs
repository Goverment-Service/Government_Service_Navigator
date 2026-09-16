namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class PaymentLogBucketDto
    {
        public string Label { get; set; } = string.Empty;
        public DateTime PeriodStart { get; set; }
        public DateTime PeriodEnd { get; set; }
        public int Count { get; set; }
        public decimal BankTransferTotal { get; set; }
        public decimal StripeTotal { get; set; }
        public decimal RefundedTotal { get; set; }
        public decimal Total { get; set; }
    }

    public class StripeIntentDto
    {
        public int PaymentId { get; set; }
        public string ClientSecret { get; set; } = string.Empty;
        public string PublishableKey { get; set; } = string.Empty;
    }
}
