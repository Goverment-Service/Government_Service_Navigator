using System.Collections.Generic;
using System.Threading.Tasks;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IServiceApplicationService
    {
        Task<ApplicationDto> SubmitApplicationAsync(int userId, SubmitApplicationRequest request);
        Task<List<ApplicationDto>> GetMyApplicationsAsync(int userId);
        Task<ApplicationDto?> GetApplicationForUserAsync(int applicationId, int userId);
    }
}
