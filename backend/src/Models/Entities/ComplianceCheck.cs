namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class ComplianceCheck
    {
        public int Id { get; set; }
        public int TaskId { get; set; }
        public string CheckType { get; set; }
        public bool IsPassed { get; set; }
        public string Details { get; set; }
        
        public VerificationTask Task { get; set; }
    }
}
