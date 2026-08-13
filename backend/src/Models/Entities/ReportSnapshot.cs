using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class ReportSnapshot
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string ReportType { get; set; } = string.Empty;
        public string DataJson { get; set; } = string.Empty;
        public int GeneratedByAdminId { get; set; }
        public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
    }
}
