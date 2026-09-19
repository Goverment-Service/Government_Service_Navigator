using Government_Service_Navigator.Backend.Models.Entities;

namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class AnomalyFlagDto
    {
        public int Id { get; set; }
        public int? PaymentId { get; set; }
        public string AnomalyType { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime DetectedDate { get; set; }
        public string? ReviewedByEmail { get; set; }
        public DateTime? ReviewedDate { get; set; }

        public static AnomalyFlagDto FromEntity(AnomalyFlag f) => new AnomalyFlagDto
        {
            Id = f.Id,
            PaymentId = f.PaymentId,
            AnomalyType = f.AnomalyType,
            Description = f.Description,
            Status = f.Status,
            DetectedDate = f.DetectedDate,
            ReviewedByEmail = f.ReviewedByEmail,
            ReviewedDate = f.ReviewedDate
        };
    }
}
