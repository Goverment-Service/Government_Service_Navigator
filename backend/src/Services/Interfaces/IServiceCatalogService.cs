using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.DTOs; // Assume DTOs are created to match

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IServiceCatalogService
    {
        Task<ServiceProcedure> CreateServiceAsync(ServiceProcedure service);
        Task<ServiceProcedure?> GetServiceByIdAsync(int id);
        Task<IEnumerable<ServiceProcedure>> GetAllServicesAsync();
        Task<ServiceProcedure> UpdateEligibilityRulesAsync(int id, List<EligibilityRule> rules);
        Task<bool> RetireServiceAsync(int id);

        // Business Operation: Scoring
        Task<EligibilityScoreResultDto> CalculateEligibilityScoreAsync(int serviceId, CitizenProfileDto profile);
        Task<ServiceProcedure?> UpdateServiceAsync(int id, ServiceProcedure updatedService);
        Task<ServiceProcedure> UpdateDocumentRequirementsAsync(int id, List<DocumentRequirement> documents);
        Task<bool> DeleteDocumentRequirementAsync(int documentId);
        Task<ServiceProcedure> UpdateFeeSchedulesAsync(int id, List<FeeSchedule> feeSchedules);
        Task<bool> DeleteFeeScheduleAsync(int feeId);
      




    }
}
