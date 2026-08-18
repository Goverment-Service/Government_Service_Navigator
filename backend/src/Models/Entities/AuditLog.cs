using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class AuditLog
    {
        public int Id { get; set; }
        public int ApplicationId { get; set; }
        public string Action { get; set; }
        public string PerformedBy { get; set; }
        public DateTime Timestamp { get; set; }
        public string OldValues { get; set; } 
        public string NewValues { get; set; } 
    }
}
