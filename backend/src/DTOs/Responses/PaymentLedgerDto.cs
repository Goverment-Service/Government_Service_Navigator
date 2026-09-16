namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class LedgerEntryDto
    {
        public string Type { get; set; } = string.Empty; // "Payment", "Refund", "Fee"
        public decimal Amount { get; set; }
        public DateTime Date { get; set; }
        public string Description { get; set; } = string.Empty;
    }

    public class PaymentLedgerDto
    {
        public int PaymentId { get; set; }
        public decimal OriginalAmount { get; set; }
        public decimal TotalRefunded { get; set; }
        public decimal RunningBalance { get; set; }
        public string Status { get; set; } = string.Empty;
        public List<LedgerEntryDto> Entries { get; set; } = new();
    }
}