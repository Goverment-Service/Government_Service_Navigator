using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.DTOs.Requests;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface ITemplateService
    {
        Task<Template> CreateTemplateAsync(CreateTemplateRequest request);
        Task<IEnumerable<Template>> GetAllTemplatesAsync(string? category = null);
        Task<Template?> GetTemplateByIdAsync(Guid id);
        Task<Template?> GetTemplateByServiceProcedureIdAsync(int serviceProcedureId);
        Task<Template> UpdateTemplateAsync(Guid id, CreateTemplateRequest request);
        Task<Template> UpdateTemplateStatusAsync(Guid id, string status);
        Task<bool> DeleteTemplateAsync(Guid id);
    }
}