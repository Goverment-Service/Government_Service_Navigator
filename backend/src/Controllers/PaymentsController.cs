using System.Security.Claims;
using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api/payments")]
    public class PaymentsController : ControllerBase
    {
        private const string FinanceRoles = "Finance Officer,Department Admin,Admin,System Admin";

        private readonly IPaymentService _paymentService;
        private readonly AppDbContext _context;

        public PaymentsController(IPaymentService paymentService, AppDbContext context)
        {
            _paymentService = paymentService;
            _context = context;
        }

        // Citizen uploads a bank transfer / cash deposit slip.
        [HttpPost("manual")]
        [Authorize]
        public async Task<IActionResult> CreateManualPayment([FromBody] CreateManualPaymentDto dto)
        {
            var payment = await _paymentService.CreateManualPaymentAsync(dto.ApplicationId, dto.Amount, dto.UserEmail, dto.ManualSlipUrl);
            return CreatedAtAction(nameof(GetById), new { id = payment.Id }, payment);
        }

        [HttpGet("{id}")]
        [Authorize]
        public async Task<IActionResult> GetById(int id)
        {
            var payment = await _paymentService.GetByIdAsync(id);
            if (payment == null) return NotFound();
            return Ok(payment);
        }

        // Citizen: list their own payments.
        [HttpGet("mine")]
        [Authorize]
        public async Task<IActionResult> GetMine()
        {
            var email = User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value 
                     ?? User.FindFirst("email")?.Value 
                     ?? User.Identity?.Name 
                     ?? "unknown@user";
            var payments = await _paymentService.GetByUserAsync(email);
            return Ok(payments);
        }

        // Finance Officer: list all pending manual bank transfer slips awaiting verification with citizen details
        [HttpGet("pending-slips")]
        [Authorize(Roles = FinanceRoles)]
        public async Task<IActionResult> GetPendingSlips()
        {
            var role = User.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
            var dept = User.FindFirstValue("department") ?? User.FindFirst("department")?.Value;
            var isSystemAdmin = role.Contains("System Admin", StringComparison.OrdinalIgnoreCase) || role == "Admin";

            var query = _context.Payments
                .Where(p => p.Status == "PendingVerification");

            if (!isSystemAdmin && !string.IsNullOrEmpty(dept))
            {
                var appSubmissions = _context.ApplicationSubmissions
                    .Where(s => s.CurrentDepartment == dept)
                    .Select(s => s.Id);

                query = query.Where(p => appSubmissions.Contains(p.ApplicationId));
            }

            var pending = await query
                .OrderByDescending(p => p.CreatedDate)
                .ToListAsync();

            var appIds = pending.Select(p => p.ApplicationId).Distinct().ToList();
            var submissions = await _context.ApplicationSubmissions
                .Include(s => s.ServiceProcedure)
                .Where(s => appIds.Contains(s.Id))
                .ToDictionaryAsync(s => s.Id);

            var nics = submissions.Values.Select(s => s.CitizenNic).Where(n => !string.IsNullOrEmpty(n)).Distinct().ToList();
            var users = await _context.Users
                .Where(u => nics.Contains(u.NicNumber))
                .ToDictionaryAsync(u => u.NicNumber, u => u.FullName);

            var result = pending.Select(p =>
            {
                submissions.TryGetValue(p.ApplicationId, out var sub);
                string citizenNic = sub?.CitizenNic ?? "";
                string citizenName = (!string.IsNullOrEmpty(citizenNic) && users.TryGetValue(citizenNic, out var fullName))
                    ? fullName
                    : (!string.IsNullOrEmpty(citizenNic) ? citizenNic : "Citizen");

                return new
                {
                    id = p.Id,
                    applicationId = p.ApplicationId,
                    referenceNumber = $"APP-{p.ApplicationId}",
                    citizenNic = citizenNic,
                    citizenName = citizenName,
                    userEmail = !string.IsNullOrEmpty(p.UserEmail) ? p.UserEmail : (sub?.UserEmail ?? ""),
                    serviceName = sub?.ServiceProcedure?.Name ?? "Government Service",
                    stageNumber = sub?.CurrentStage ?? 1,
                    department = sub?.CurrentDepartment ?? dept ?? "",
                    method = p.Method,
                    amount = p.Amount,
                    status = p.Status,
                    manualSlipUrl = p.ManualSlipUrl,
                    referenceNumberOrId = !string.IsNullOrEmpty(p.StripePaymentIntentId)
                        ? p.StripePaymentIntentId
                        : (!string.IsNullOrEmpty(p.ManualSlipUrl) ? p.ManualSlipUrl.Split('/').LastOrDefault() : "N/A"),
                    submittedAt = p.CreatedDate,
                    createdDate = p.CreatedDate,
                    paidDate = p.PaidDate
                };
            }).ToList();

            return Ok(result);
        }

        // Finance Officer: list all payments (Pending, Verified, Failed) for this department with citizen details
        [HttpGet("department-payments")]
        [Authorize(Roles = FinanceRoles)]
        public async Task<IActionResult> GetDepartmentPayments()
        {
            var role = User.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
            var dept = User.FindFirstValue("department") ?? User.FindFirst("department")?.Value;
            var isSystemAdmin = role.Contains("System Admin", StringComparison.OrdinalIgnoreCase) || role == "Admin";

            var query = _context.Payments.AsQueryable();

            if (!isSystemAdmin && !string.IsNullOrEmpty(dept))
            {
                var appSubmissions = _context.ApplicationSubmissions
                    .Where(s => s.CurrentDepartment == dept)
                    .Select(s => s.Id);

                query = query.Where(p => appSubmissions.Contains(p.ApplicationId));
            }

            var payments = await query
                .OrderByDescending(p => p.CreatedDate)
                .ToListAsync();

            var appIds = payments.Select(p => p.ApplicationId).Distinct().ToList();
            var submissions = await _context.ApplicationSubmissions
                .Include(s => s.ServiceProcedure)
                .Where(s => appIds.Contains(s.Id))
                .ToDictionaryAsync(s => s.Id);

            var nics = submissions.Values.Select(s => s.CitizenNic).Where(n => !string.IsNullOrEmpty(n)).Distinct().ToList();
            var users = await _context.Users
                .Where(u => nics.Contains(u.NicNumber))
                .ToDictionaryAsync(u => u.NicNumber, u => u.FullName);

            var result = payments.Select(p =>
            {
                submissions.TryGetValue(p.ApplicationId, out var sub);
                string citizenNic = sub?.CitizenNic ?? "";
                string citizenName = (!string.IsNullOrEmpty(citizenNic) && users.TryGetValue(citizenNic, out var fullName))
                    ? fullName
                    : (!string.IsNullOrEmpty(citizenNic) ? citizenNic : "Citizen");

                return new
                {
                    id = p.Id,
                    applicationId = p.ApplicationId,
                    referenceNumber = $"APP-{p.ApplicationId}",
                    citizenNic = citizenNic,
                    citizenName = citizenName,
                    userEmail = !string.IsNullOrEmpty(p.UserEmail) ? p.UserEmail : (sub?.UserEmail ?? ""),
                    serviceName = sub?.ServiceProcedure?.Name ?? "Government Service",
                    stageNumber = sub?.CurrentStage ?? 1,
                    department = sub?.CurrentDepartment ?? dept ?? "",
                    method = p.Method,
                    amount = p.Amount,
                    status = p.Status, // "PendingVerification", "Paid", "Failed"
                    manualSlipUrl = p.ManualSlipUrl,
                    referenceNumberOrId = !string.IsNullOrEmpty(p.StripePaymentIntentId)
                        ? p.StripePaymentIntentId
                        : (!string.IsNullOrEmpty(p.ManualSlipUrl) ? p.ManualSlipUrl.Split('/').LastOrDefault() : "N/A"),
                    submittedAt = p.CreatedDate,
                    createdDate = p.CreatedDate,
                    paidDate = p.PaidDate
                };
            }).ToList();

            return Ok(result);
        }

        // Finance Officer verifies/rejects a manual payment slip.
        [HttpPost("{id}/verify")]
        [Authorize(Roles = FinanceRoles)]
        public async Task<IActionResult> Verify(int id, [FromBody] VerifyManualPaymentDto dto)
        {
            var role = User.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
            var dept = User.FindFirstValue("department") ?? User.FindFirst("department")?.Value;
            var isSystemAdmin = role.Contains("System Admin", StringComparison.OrdinalIgnoreCase) || role == "Admin";

            if (!isSystemAdmin && !string.IsNullOrEmpty(dept))
            {
                var paymentItem = await _context.Payments.FindAsync(id);
                if (paymentItem != null)
                {
                    var submission = await _context.ApplicationSubmissions.FindAsync(paymentItem.ApplicationId);
                    if (submission != null && !string.IsNullOrEmpty(submission.CurrentDepartment) && !string.Equals(submission.CurrentDepartment, dept, StringComparison.OrdinalIgnoreCase))
                    {
                        return Forbid();
                    }
                }
            }

            try
            {
                var payment = await _paymentService.VerifyManualPaymentAsync(id, dto.Approved, dto.Note);

                var officerId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.Identity?.Name ?? "Finance Officer";
                _context.AuditLogs.Add(new AuditLog
                {
                    ApplicationId = payment.ApplicationId,
                    Action = dto.Approved ? "Payment Verified" : "Payment Rejected",
                    PerformedBy = officerId,
                    Timestamp = DateTime.UtcNow,
                    OldValues = $"PaymentId: {payment.Id}, PreviousStatus: PendingVerification, Amount: {payment.Amount}",
                    NewValues = $"Status: {payment.Status}, Decision: {(dto.Approved ? "Approved" : "Rejected")}, Notes: {dto.Note ?? (dto.Approved ? "Payment verified by Finance Officer" : "Payment rejected by Finance Officer")}"
                });
                await _context.SaveChangesAsync();

                return Ok(payment);
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
            catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        }

        // Finance Officer updates/edits payment status (Paid, Failed, PendingVerification)
        [HttpPut("{id}/status")]
        [Authorize(Roles = FinanceRoles)]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdatePaymentStatusDto dto)
        {
            var role = User.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
            var dept = User.FindFirstValue("department") ?? User.FindFirst("department")?.Value;
            var isSystemAdmin = role.Contains("System Admin", StringComparison.OrdinalIgnoreCase) || role == "Admin";

            if (!isSystemAdmin && !string.IsNullOrEmpty(dept))
            {
                var paymentItem = await _context.Payments.FindAsync(id);
                if (paymentItem != null)
                {
                    var submission = await _context.ApplicationSubmissions.FindAsync(paymentItem.ApplicationId);
                    if (submission != null && !string.IsNullOrEmpty(submission.CurrentDepartment) && !string.Equals(submission.CurrentDepartment, dept, StringComparison.OrdinalIgnoreCase))
                    {
                        return Forbid();
                    }
                }
            }

            try
            {
                var officerId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.Identity?.Name ?? "Finance Officer";
                var payment = await _paymentService.UpdatePaymentStatusAsync(id, dto.Status, dto.Note, officerId);
                return Ok(payment);
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
            catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        }

        [HttpGet("{id}/ledger")]
        [Authorize]
        public async Task<IActionResult> GetLedger(int id)
        {
            try
            {
                var ledger = await _paymentService.GetLedgerAsync(id);
                return Ok(ledger);
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
        }

        [HttpPost("checkout")]
        [Authorize]
        public async Task<IActionResult> CreateCheckout([FromBody] CreateCheckoutSessionDto dto)
        {
            var (payment, checkoutUrl) = await _paymentService.CreateStripeCheckoutAsync(dto.ApplicationId, dto.Amount, dto.UserEmail);
            return Ok(new { paymentId = payment.Id, checkoutUrl });
        }

        // Testing-only helper: manually check Stripe session status without needing a webhook.
        [HttpGet("{id}/confirm")]
        [Authorize]
        public async Task<IActionResult> ConfirmPayment(int id)
        {
            try
            {
                var payment = await _paymentService.ConfirmStripePaymentAsync(id);
                return Ok(payment);
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
            catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        }
    }
}