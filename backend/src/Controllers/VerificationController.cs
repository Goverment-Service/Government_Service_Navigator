using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // Require JWT token
    public class VerificationController : ControllerBase
    {
        private readonly IVerificationService _verificationService;

        public VerificationController(IVerificationService verificationService)
        {
            _verificationService = verificationService;
        }

        // The "sub" JWT claim is inbound-mapped to ClaimTypes.NameIdentifier by the JWT bearer
        // handler; User.Identity.Name (ClaimTypes.Name) is never set, so it always reads null.
        private string GetCurrentOfficerId() =>
            User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.Identity?.Name ?? "Unknown";

        [HttpGet("tasks/pending")]
        public async Task<IActionResult> GetPendingTasks()
        {
            var tasks = await _verificationService.GetPendingTasksAsync();
            return Ok(tasks);
        }

        [HttpGet("stats")]
        public async Task<IActionResult> GetOfficerStats()
        {
            var stats = await _verificationService.GetOfficerStatsAsync(GetCurrentOfficerId());
            return Ok(stats);
        }

        [HttpPost("tasks")]
        public async Task<IActionResult> CreateVerificationTask([FromBody] CreateTaskRequest request)
        {
            var task = await _verificationService.CreateTaskAsync(request, GetCurrentOfficerId());
            return Ok(task);
        }

        [HttpGet("audit-logs")]
        public async Task<IActionResult> GetAuditLogs([FromQuery] int applicationId)
        {
            var logs = await _verificationService.GetAuditLogsAsync(applicationId);
            return Ok(logs);
        }

        [HttpGet("audit-logs/all")]
        public async Task<IActionResult> GetAllAuditLogs()
        {
            var logs = await _verificationService.GetAllAuditLogsAsync();
            return Ok(logs);
        }

        [HttpPut("tasks/{id}/decision")]
        public async Task<IActionResult> RecordDecision(int id, [FromBody] VerificationDecisionRequest request)
        {
            var result = await _verificationService.RecordDecisionAsync(id, request, GetCurrentOfficerId());

            if (!result) return NotFound("Task not found or update failed");
            return Ok();
        }

        [HttpDelete("tasks/{id}")]
        public async Task<IActionResult> DeleteTask(int id)
        {
            var result = await _verificationService.DeleteTaskAsync(id, GetCurrentOfficerId());

            if (!result) return NotFound();
            return NoContent();
        }

        [HttpPost("tasks/bulk-verify")]
        public async Task<IActionResult> BulkVerify([FromBody] BulkVerifyRequest request)
        {
            var result = await _verificationService.BulkVerifyAsync(request, GetCurrentOfficerId());

            if (!result) return BadRequest("Bulk verification failed");
            return Ok();
        }
    }
}
