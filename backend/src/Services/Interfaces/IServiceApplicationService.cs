using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IServiceApplicationService
    {
        Task<ApplicationDto> SubmitApplicationAsync(int userId, SubmitApplicationRequest request);
        Task<List<ApplicationDto>> GetMyApplicationsAsync(int userId);
        Task<ApplicationDto?> GetApplicationForUserAsync(int applicationId, int userId);

        Task<ApplicationDocumentDto> UploadDocumentAsync(int applicationId, int userId, int? documentRequirementId, string documentName, IFormFile file);
        Task<List<ApplicationDocumentDto>> GetDocumentsForUserAsync(int applicationId, int userId);
        Task<SlipFileResult?> GetDocumentFileForUserAsync(int applicationId, int documentId, int userId);
    }
}
