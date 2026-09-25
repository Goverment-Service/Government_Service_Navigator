using System.Collections.Generic;

namespace Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.DTOs;

public class CitizenProfile
{
    public int Age { get; set; } = 25;
    public string CitizenshipStatus { get; set; } = "Sri Lankan";
    public decimal AnnualIncome { get; set; } = 0;
    public string EmploymentStatus { get; set; } = "Employed";
    public List<string> ProvidedDocuments { get; set; } = new();
    public Dictionary<string, string> AdditionalAttributes { get; set; } = new();
}
