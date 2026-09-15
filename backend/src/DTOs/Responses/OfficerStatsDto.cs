namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class OfficerStatsDto
    {
        public int ReviewedToday { get; set; }
        public int ReviewedYesterday { get; set; }
        public int ApprovedThisMonth { get; set; }
        // Share of this officer's Approved/Rejected decisions that were Approved. Null when the officer has no decisions yet.
        public double? ApprovalRate { get; set; }
    }
}
