using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api/payments")]
    public class PaymentsController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentsController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
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

        // Finance Officer verifies/rejects a manual payment slip.
        [HttpPost("{id}/verify")]
        [Authorize]
        public async Task<IActionResult> Verify(int id, [FromBody] VerifyManualPaymentDto dto)
        {
            try
            {
                var payment = await _paymentService.VerifyManualPaymentAsync(id, dto.Approved, dto.Note);
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