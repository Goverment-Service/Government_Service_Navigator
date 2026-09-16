using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
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

        [HttpPost("{id}/documents")]
        [RequestSizeLimit(15 * 1024 * 1024)]
        public async Task<IActionResult> UploadDocument(int id, [FromForm] int? documentRequirementId, [FromForm] string documentName, [FromForm] IFormFile file)
        {
            try
            {
                var document = await _applicationService.UploadDocumentAsync(id, GetCurrentUserId(), documentRequirementId, documentName, file);
                return Ok(document);
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{id}/documents")]
        public async Task<IActionResult> GetDocuments(int id)
        {
            var documents = await _applicationService.GetDocumentsForUserAsync(id, GetCurrentUserId());
            return Ok(documents);
        }

        [HttpGet("{id}/documents/{documentId}/file")]
        public async Task<IActionResult> GetDocumentFile(int id, int documentId)
        {
            var file = await _applicationService.GetDocumentFileForUserAsync(id, documentId, GetCurrentUserId());
            if (file == null) return NotFound();
            return File(file.Bytes, file.ContentType, file.FileName);
        }
    }
}
