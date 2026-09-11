namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class ServiceProcedure
    {
        public int Id { get; set; }
        public required string ServiceId { get; set; } // e.g., "GSN-SRV-001"
        public required string Name { get; set; }
        public required string Category { get; set; }
        public string Status { get; set; } = "Draft"; // Draft, Active, Retired

        // Navigation properties
        public List<EligibilityRule> EligibilityRules { get; set; } = new();
        public List<DocumentRequirement> DocumentRequirements { get; set; } = new();
        public List<FeeSchedule> FeeSchedules { get; set; } = new();
    }
}
