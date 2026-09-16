using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Controllers
{
    // All payment-management operations for the Finance Officer dashboard.
    // Restricted to Officer accounts whose Role is exactly "Finance Officer".
    [ApiController]
    [Route("api/finance")]
    [Authorize(Roles = "Finance Officer")]
    public class FinancePaymentsController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public FinancePaymentsController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        private string GetCurrentOfficerId() =>
            User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.Identity?.Name ?? "Unknown";

        [HttpGet("payments")]
        public async Task<IActionResult> GetAllPayments([FromQuery] string? status, [FromQuery] string? method, [FromQuery] string? search)
        {
            var payments = await _paymentService.GetAllPaymentsAsync(status, method, search);
            return Ok(payments);
        }

        [HttpGet("payments/pending-bank")]
        public async Task<IActionResult> GetPendingBankPayments()
        {
            var payments = await _paymentService.GetPendingBankPaymentsAsync();
            return Ok(payments);
        }

        [HttpGet("payments/stripe")]
        public async Task<IActionResult> GetStripePayments()
        {
            var payments = await _paymentService.GetStripePaymentsAsync();
            return Ok(payments);
        }

        [HttpGet("payments/{id}")]
        public async Task<IActionResult> GetPayment(int id)
        {
            var payment = await _paymentService.GetPaymentByIdAsync(id);
            if (payment == null) return NotFound();
            return Ok(payment);
        }

        [HttpGet("payments/{id}/slip")]
        public async Task<IActionResult> GetSlip(int id)
        {
            var slip = await _paymentService.GetSlipAsync(id);
            if (slip == null) return NotFound();
            return File(slip.Bytes, slip.ContentType, slip.FileName);
        }

        [HttpPut("payments/{id}/verify")]
        public async Task<IActionResult> VerifyPayment(int id, [FromBody] VerifyPaymentDecisionRequest request)
        {
            try
            {
                var payment = await _paymentService.VerifyPaymentAsync(id, request, GetCurrentOfficerId());
                if (payment == null) return NotFound(new { message = "Payment not found or is not a pending bank transfer." });
                return Ok(payment);
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("payments/logs")]
        public async Task<IActionResult> GetLogs([FromQuery] string period = "daily")
        {
            var logs = await _paymentService.GetLogsAsync(period);
            return Ok(logs);
        }

        [HttpGet("refunds")]
        public async Task<IActionResult> GetRefundRequests([FromQuery] string? status)
        {
            var refunds = await _paymentService.GetRefundRequestsAsync(status);
            return Ok(refunds);
        }

        [HttpGet("refunds/{id}")]
        public async Task<IActionResult> GetRefund(int id)
        {
            var refund = await _paymentService.GetRefundByIdAsync(id);
            if (refund == null) return NotFound();
            return Ok(refund);
        }

        [HttpPut("refunds/{id}/process")]
        public async Task<IActionResult> ProcessRefund(int id, [FromBody] ProcessRefundRequest request)
        {
            try
            {
                var refund = await _paymentService.ProcessRefundAsync(id, request, GetCurrentOfficerId());
                if (refund == null) return NotFound();
                return Ok(refund);
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("refunds/history/all")]
        public async Task<IActionResult> GetRefundHistory()
        {
            var refunds = await _paymentService.GetRefundHistoryAsync();
            return Ok(refunds);
        }
    }
}
