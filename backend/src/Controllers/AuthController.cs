using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid)
            {
                var errors = string.Join(" ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
                return Ok(new AuthResponse { Success = false, ErrorMessage = errors });
            }

            try
            {
                var response = await _authService.RegisterAsync(request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return Ok(new AuthResponse { Success = false, ErrorMessage = ex.Message });
            }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid)
            {
                var errors = string.Join(" ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
                return Ok(new AuthResponse { Success = false, ErrorMessage = errors });
            }

            try
            {
                var response = await _authService.LoginAsync(request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return Ok(new AuthResponse { Success = false, ErrorMessage = ex.Message });
            }
        }

        [HttpPost("officer-login")]
        public async Task<IActionResult> OfficerLogin([FromBody] LoginRequest request)
        {
            if(!ModelState.IsValid) {
                var errors = string.Join(" ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
                return Ok(
                    new AuthResponse {
                        Success =  false,
                        ErrorMessage = errors
                    }
                );
            } 
            try {
                var response = await _authService.OfficerLoginAsync(request);
                return Ok(response);
            } catch (Exception ex) {
                return Ok (
                    new AuthResponse {
                        Success = false,
                        ErrorMessage = ex.Message
                    }
                );
            }
        }
        [HttpPost("admin-login")]
        public async Task<IActionResult> AdminLogin([FromBody] LoginRequest request)
        {
            if(!ModelState.IsValid) {
                var errors = string.Join(" ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
                return Ok(
                    new AuthResponse {
                        Success =  false,
                        ErrorMessage = errors
                    }
                );
            } 
            try {
                var response = await _authService.AdminLoginAsync(request);
                return Ok(response);
            } catch (Exception ex) {
                return Ok (
                    new AuthResponse {
                        Success = false,
                        ErrorMessage = ex.Message
                    }
                );
            }
        }
        [Authorize]
        [HttpPost("logout")]
        public async Task<IActionResult> Logout()
        {
            var jti = User.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;
            var expClaim = User.FindFirst(JwtRegisteredClaimNames.Exp)?.Value;

            if (!string.IsNullOrEmpty(jti))
            {
                var expiresAt = long.TryParse(expClaim, out var expUnixSeconds)
                    ? DateTimeOffset.FromUnixTimeSeconds(expUnixSeconds).UtcDateTime
                    : DateTime.UtcNow.AddDays(7);

                await _authService.LogoutAsync(jti, expiresAt);
            }

            return Ok(new AuthResponse {
                Success = true,
                ErrorMessage = "Logged out successfully"
            });
        }
    }
}