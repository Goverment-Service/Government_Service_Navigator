using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class ReportSnapshot
    {
        public int Id { get; set; }

        public string Title { get; set; } = string.Empty;

        // "Daily", "Weekly", "Monthly", "Yearly"
        public string Period { get; set; } = string.Empty;

        public DateTime GeneratedDate { get; set; } = DateTime.UtcNow;

        // Serialized report data (JSON), so different report shapes don't need separate tables.
        public string DataJson { get; set; } = string.Empty;

        public string GeneratedByEmail { get; set; } = string.Empty;
    }
}