using System.Threading.Tasks;

namespace Government_Service_Navigator.AgenticAi.Tools.CheckDuplicateApplication
{
    public interface IDuplicateApplicationRepository
    {
        Task<bool> HasDuplicateAsync(string citizenNic, int serviceProcedureId);
    }
}
