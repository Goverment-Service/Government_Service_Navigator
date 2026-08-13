using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class RefundRequest
    {
        public int Id { get; set; }
        public int PaymentId { get; set; }
        public string Reason { get; set; } = string.Empty;
        public RefundStatus Status { get; set; } = RefundStatus.Requested;
        public int? ReviewedByOfficerId { get; set; }
        public string? OfficerNotes { get; set; }
        public DateTime RequestedAt { get; set; } = DateTime.UtcNow;
        public DateTime? ResolvedAt { get; set; }
    }
}
