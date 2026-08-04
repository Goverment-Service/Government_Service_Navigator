using System.Threading.Tasks;
using GSN.Application.Auth;
using Microsoft.AspNetCore.Mvc;

namespace GSN.Api.Controllers {
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase {
        private readonly AuthService _authService;

        public AuthController(AuthService authService) {
            _authService = authService;
        }

        // POST /api/auth/register
        [HttpPost("register")]
        public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request) {
            var result = await _authService.RegisterAsync(request);

            if (!result.Success) {
                return BadRequest(result);
            }

            return Ok(result);
        }

        // POST /api/auth/login
        [HttpPost("login")]
        public async Task<ActionResult<AuthResponse>> Login(LoginRequest request) {
            var result = await _authService.LoginAsync(request);

            if (!result.Success) {
                return Unauthorized(result);
            }

            return Ok(result);
        }
    }
}