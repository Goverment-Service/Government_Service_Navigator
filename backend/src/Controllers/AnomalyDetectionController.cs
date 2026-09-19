using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api/anomalies")]
    public class AnomalyDetectionController : ControllerBase
    {
        private readonly IAnomalyDetectionService _anomalyService;

        public AnomalyDetectionController(IAnomalyDetectionService anomalyService)
        {
            _anomalyService = anomalyService;
        }

        // Triggers a full rule-based scan and returns any newly created flags.
        [HttpPost("scan")]
        [Authorize]
        public async Task<IActionResult> Scan()
        {
            var newFlags = await _anomalyService.ScanAsync();
            return Ok(newFlags.Select(AnomalyFlagDto.FromEntity));
        }

        // Returns all flags currently in the "Open" state.
        [HttpGet("open")]
        [Authorize]
        public async Task<IActionResult> GetOpenFlags()
        {
            var flags = await _anomalyService.GetOpenFlagsAsync();
            return Ok(flags.Select(AnomalyFlagDto.FromEntity));
        }

        // Officer marks a flag as "Reviewed" or "Dismissed".
        [HttpPost("{id}/resolve")]
        [Authorize]
        public async Task<IActionResult> Resolve(int id, [FromBody] ResolveFlagRequest dto)
        {
            var allowed = new[] { "Reviewed", "Dismissed" };
            if (!allowed.Contains(dto.Status))
            {
                return BadRequest($"Status must be one of: {string.Join(", ", allowed)}.");
            }

            var email = User.Identity?.Name ?? "unknown@officer";

            try
            {
                var flag = await _anomalyService.ResolveFlagAsync(id, dto.Status, email);
                return Ok(AnomalyFlagDto.FromEntity(flag));
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
        }
    }
}
