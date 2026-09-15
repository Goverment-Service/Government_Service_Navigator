using System;
using System.Threading.Tasks;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponse> RegisterAsync(RegisterRequest request);
        Task<AuthResponse> LoginAsync(LoginRequest request);
        Task<AuthResponse> OfficerLoginAsync(LoginRequest request);
        Task<AuthResponse> AdminLoginAsync(LoginRequest request);
        Task LogoutAsync(string jti, DateTime expiresAt);
    }
}
