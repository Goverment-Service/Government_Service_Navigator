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

        [HttpPost("tasks")]
        public async Task<IActionResult> CreateVerificationTask([FromBody] CreateTaskRequest request)
        {
            var agentId = User.Identity?.Name ?? "SystemAgent";
            var task = await _verificationService.CreateTaskAsync(request, agentId);
            return Ok(task);
        }

        [HttpGet("audit-logs")]
        public async Task<IActionResult> GetAuditLogs([FromQuery] int applicationId)
        {
            var logs = await _verificationService.GetAuditLogsAsync(applicationId);
            return Ok(logs);
        }

        [HttpPut("tasks/{id}/decision")]
        public async Task<IActionResult> RecordDecision(int id, [FromBody] VerificationDecisionRequest request)
        {
            var officerId = User.Identity?.Name ?? "Unknown"; 
            var result = await _verificationService.RecordDecisionAsync(id, request, officerId);
            
            if (!result) return NotFound("Task not found or update failed");
            return Ok();
        }

        [HttpDelete("tasks/{id}")]
        public async Task<IActionResult> DeleteTask(int id)
        {
            var officerId = User.Identity?.Name ?? "Unknown";
            var result = await _verificationService.DeleteTaskAsync(id, officerId);
            
            if (!result) return NotFound();
            return NoContent();
        }

        [HttpPost("tasks/bulk-verify")]
        public async Task<IActionResult> BulkVerify([FromBody] BulkVerifyRequest request)
        {
            var officerId = User.Identity?.Name ?? "Unknown";
            var result = await _verificationService.BulkVerifyAsync(request, officerId);
            
            if (!result) return BadRequest("Bulk verification failed");
            return Ok();
        }
    }
}
