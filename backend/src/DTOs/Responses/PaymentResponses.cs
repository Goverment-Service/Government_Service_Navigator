using System;
using System.Collections.Generic;

namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class RefundRequestDto
    {
        public int Id { get; set; }
        public int PaymentId { get; set; }
        public string Reason { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime RequestedAt { get; set; }
        public DateTime? ResolvedAt { get; set; }
    }

    public class RefundResponse
    {
        public bool Success { get; set; }
        public string? ErrorMessage { get; set; }
        public RefundRequestDto? RefundRequest { get; set; }
    }

    public class LedgerEntryDto
    {
        public string Type { get; set; } = string.Empty; // "Payment", "Refund", "Installment"
        public string Description { get; set; } = string.Empty;
        public decimal Amount { get; set; } // positive = credit/charge, negative = refund
        public DateTime Date { get; set; }
        public string Status { get; set; } = string.Empty;
    }

    public class LedgerDto
    {
        public int PaymentId { get; set; }
        public int ApplicationId { get; set; }
        public decimal OriginalAmount { get; set; }
        public string Currency { get; set; } = string.Empty;
        public string PaymentStatus { get; set; } = string.Empty;
        public decimal RunningBalance { get; set; }
        public List<LedgerEntryDto> Entries { get; set; } = new List<LedgerEntryDto>();
    }

    public class LedgerResponse
    {
        public bool Success { get; set; }
        public string? ErrorMessage { get; set; }
        public LedgerDto? Ledger { get; set; }
    }
}
