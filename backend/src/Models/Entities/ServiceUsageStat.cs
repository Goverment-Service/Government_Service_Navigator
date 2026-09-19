using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class ServiceUsageStat
    {
        public int Id { get; set; }

        public int ServiceProcedureId { get; set; }
        public DateTime Date { get; set; }

        public int TotalApplications { get; set; }
        public int ApprovedCount { get; set; }
        public int RejectedCount { get; set; }

        // Average time from submission to decision, in hours.
        public double AverageProcessingHours { get; set; }
    }
}