using System.Threading.Tasks;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using System.Collections.Generic;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IAdminService
    {
        Task<IEnumerable<OfficerDetailsDto>> GetAllOfficersAsync();
        Task<AuthResponse> CreateOfficerAsync(CreateOfficerRequest request);
    }
}
