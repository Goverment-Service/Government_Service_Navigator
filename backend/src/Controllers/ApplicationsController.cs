using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Controllers
{
    // Citizen-facing service applications - submit an application against a
    // ServiceProcedure and track its status, which mirrors the existing
    // Officer verification queue.
    [ApiController]
    [Route("api/applications")]
    [Authorize]
    public class ApplicationsController : ControllerBase
    {
        private readonly IServiceApplicationService _applicationService;

        public ApplicationsController(IServiceApplicationService applicationService)
        {
            _applicationService = applicationService;
        }

        private int GetCurrentUserId()
        {
            var sub = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
            return int.TryParse(sub, out var id) ? id : 0;
        }

        [HttpPost]
        public async Task<IActionResult> SubmitApplication([FromBody] SubmitApplicationRequest request)
        {
            try
            {
                var application = await _applicationService.SubmitApplicationAsync(GetCurrentUserId(), request);
                return Ok(application);
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("my")]
        public async Task<IActionResult> GetMyApplications()
        {
            var applications = await _applicationService.GetMyApplicationsAsync(GetCurrentUserId());
            return Ok(applications);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetApplication(int id)
        {
            var application = await _applicationService.GetApplicationForUserAsync(id, GetCurrentUserId());
            if (application == null) return NotFound();
            return Ok(application);
        }
    }
}
