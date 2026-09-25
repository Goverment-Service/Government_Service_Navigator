using System.Security.Claims;
using Government_Service_Navigator.Backend.Data.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Controllers
{
    // The signed-in citizen's in-app notifications (installment reminders, cancellations).
    [ApiController]
    [Route("api/notifications")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public NotificationsController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("mine")]
        public async Task<IActionResult> GetMine()
        {
            var notifications = await Mine()
                .OrderByDescending(n => n.CreatedAt)
                .Take(100)
                .ToListAsync();
            return Ok(notifications);
        }

        [HttpPost("{id:int}/read")]
        public async Task<IActionResult> MarkRead(int id)
        {
            var notification = await Mine().FirstOrDefaultAsync(n => n.Id == id);
            if (notification == null) return NotFound();

            notification.ReadAt ??= DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return Ok(notification);
        }

        [HttpPost("read-all")]
        public async Task<IActionResult> MarkAllRead()
        {
            var unread = await Mine().Where(n => n.ReadAt == null).ToListAsync();
            foreach (var n in unread) n.ReadAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // Matched by the NIC claim, or by email for notifications addressed to the payer email only
        private IQueryable<Models.Entities.CitizenNotification> Mine()
        {
            var nic = User.FindFirstValue("nicNumber") ?? string.Empty;
            var email = (User.FindFirstValue(ClaimTypes.Email) ?? User.FindFirstValue("email") ?? string.Empty).ToLower();

            return _context.CitizenNotifications.Where(n =>
                (nic != string.Empty && n.CitizenNic == nic) ||
                (email != string.Empty && n.UserEmail.ToLower() == email));
        }
    }
}
