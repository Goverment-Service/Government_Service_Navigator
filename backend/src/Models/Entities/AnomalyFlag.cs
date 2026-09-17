using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class AnomalyFlag
    {
        public int Id { get; set; }

        public int? PaymentId { get; set; }

        public string AnomalyType { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;

        // "Open", "Reviewed", "Dismissed"
        public string Status { get; set; } = "Open";

        public DateTime DetectedDate { get; set; } = DateTime.UtcNow;
        public string? ReviewedByEmail { get; set; }
        public DateTime? ReviewedDate { get; set; }
    }
}