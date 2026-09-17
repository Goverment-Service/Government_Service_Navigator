using Government_Service_Navigator.Backend.Data.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api/audit-logs")]
    public class AuditLogsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AuditLogsController(AppDbContext context)
        {
            _context = context;
        }

        // Existing: all logs for a given application.
        [HttpGet]
        [Authorize]
        public async Task<IActionResult> GetByApplication([FromQuery] int applicationId)
        {
            var logs = await _context.AuditLogs
                .Where(a => a.ApplicationId == applicationId)
                .OrderByDescending(a => a.Timestamp)
                .ToListAsync();

            return Ok(logs);
        }

        // Fetch a single audit-log entry by its own id.
        [HttpGet("{id}")]
        [Authorize]
        public async Task<IActionResult> GetById(int id)
        {
            var log = await _context.AuditLogs.FindAsync(id);
            if (log == null) return NotFound($"Audit log {id} not found.");
            return Ok(log);
        }

        // All logs produced by a specific officer / user email.
        [HttpGet("by-performer")]
        [Authorize]
        public async Task<IActionResult> GetByPerformer([FromQuery] string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                return BadRequest("email query parameter is required.");

            var logs = await _context.AuditLogs
                .Where(a => a.PerformedBy == email)
                .OrderByDescending(a => a.Timestamp)
                .ToListAsync();

            return Ok(logs);
        }

        // All logs for a specific action type (e.g. "RefundApproved", "PaymentVerified").
        [HttpGet("by-action")]
        [Authorize]
        public async Task<IActionResult> GetByAction([FromQuery] string action)
        {
            if (string.IsNullOrWhiteSpace(action))
                return BadRequest("action query parameter is required.");

            var logs = await _context.AuditLogs
                .Where(a => a.Action == action)
                .OrderByDescending(a => a.Timestamp)
                .ToListAsync();

            return Ok(logs);
        }

        // Paginated recent logs across all applications — useful for an admin activity feed.
        // Defaults: page=1, pageSize=20 (capped at 100).
        [HttpGet("recent")]
        [Authorize]
        public async Task<IActionResult> GetRecent([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (page < 1) page = 1;
            if (pageSize < 1 || pageSize > 100) pageSize = 20;

            var total = await _context.AuditLogs.CountAsync();

            var logs = await _context.AuditLogs
                .OrderByDescending(a => a.Timestamp)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return Ok(new
            {
                Page = page,
                PageSize = pageSize,
                TotalCount = total,
                TotalPages = (int)Math.Ceiling((double)total / pageSize),
                Items = logs
            });
        }
    }
}