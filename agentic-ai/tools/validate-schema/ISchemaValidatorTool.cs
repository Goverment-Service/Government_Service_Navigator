using System.Collections.Generic;
using System.Threading.Tasks;
using Government_Service_Navigator.AgenticAi.Schemas;

namespace Government_Service_Navigator.AgenticAi.Tools.ValidateSchema
{
    public class SchemaValidationOutcome
    {
        public bool IsValid { get; set; }
        public List<string> Errors { get; set; } = new();
        public List<ComplianceCheckItem> ComplianceChecks { get; set; } = new();
    }

    public interface ISchemaValidatorTool
    {
        Task<SchemaValidationOutcome> ValidateAsync(DraftApplication draft, List<string>? requiredDocuments = null);
    }
}
