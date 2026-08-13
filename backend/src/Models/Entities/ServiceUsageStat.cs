using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class ServiceUsageStat
    {
        public int Id { get; set; }
        public int ServiceId { get; set; }
        public DateTime Date { get; set; }
        public int ApplicationCount { get; set; }
        public int ApprovalCount { get; set; }
        public int RejectionCount { get; set; }
        public double AvgProcessingTimeMinutes { get; set; }
    }
}
