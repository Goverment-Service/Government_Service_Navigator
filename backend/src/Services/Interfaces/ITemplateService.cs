using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.DTOs.Requests;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface ITemplateService
    {
        Task<Template> CreateTemplateAsync(CreateTemplateRequest request);
        Task<IEnumerable<Template>> GetAllTemplatesAsync();
        Task<Template?> GetTemplateByIdAsync(Guid id);
        Task<Template> UpdateTemplateAsync(Guid id, CreateTemplateRequest request);
        Task<Template> UpdateTemplateStatusAsync(Guid id, string status);
        Task<bool> DeleteTemplateAsync(Guid id);
    }
}