using System.Threading.Tasks;
using Government_Service_Navigator.AgenticAi.Schemas;

namespace Government_Service_Navigator.AgenticAi.Tools.CheckDuplicateApplication
{
    public class DuplicateCheckOutcome
    {
        public bool IsDuplicate { get; set; }
        public string? ExistingReference { get; set; }
        public string Message { get; set; } = string.Empty;
        public ComplianceCheckItem ComplianceCheck { get; set; } = new();
    }

    public interface IDuplicateCheckTool
    {
        Task<DuplicateCheckOutcome> CheckAsync(string citizenNic, int serviceProcedureId, int currentApplicationId = 0);
        void RegisterApplication(string citizenNic, int serviceProcedureId, string reference);
    }
}
