using System.Collections.Generic;

namespace Government_Service_Navigator.AgenticAi.Tools.GetDocumentRequirements;

public interface IGetDocumentRequirementsTool
{
    List<string> GetRequiredDocumentsForService(int serviceId);
}

public class GetDocumentRequirementsTool : IGetDocumentRequirementsTool
{
    public List<string> GetRequiredDocumentsForService(int serviceId)
    {
        return new List<string>
        {
            "National Identity Card (NIC) / Passport",
            "Proof of Permanent Address (Utility Bill / Grama Niladhari Certificate)",
            "Completed Application Form"
        };
    }
}
