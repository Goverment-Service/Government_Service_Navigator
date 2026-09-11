namespace Government_Service_Navigator.Backend.DTOs
{
    public class EligibilityRequestDto
    {
        public int ServiceId { get; set; }
        public required CitizenProfileDto CitizenProfile { get; set; }
    }

    public class CitizenProfileDto
    {
        public int Age { get; set; }
        public required string Citizenship { get; set; }
        public decimal MonthlyIncome { get; set; }
        // Add other dynamic fields as a dictionary if needed
    }

    public class EligibilityScoreResultDto
    {
        public double MatchPercentage { get; set; }
        public bool IsEligible { get; set; }
        public List<string> MissingCriteria { get; set; } = new();
    }
}
