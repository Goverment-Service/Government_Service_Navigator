namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class UsageAggregateDto
    {
        public string Period { get; set; } = string.Empty; // e.g. "2026-09-17", "2026-W38", "2026-09", "2026"
        public int TotalApplications { get; set; }
        public int ApprovedCount { get; set; }
        public int RejectedCount { get; set; }
        public double AverageProcessingHours { get; set; }
    }

    public class ApprovalLikelihoodDto
    {
        public int ServiceProcedureId { get; set; }
        public double ApprovalLikelihoodPercent { get; set; }
        public int SampleSize { get; set; }
    }
}