using System.IO;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Controllers
{
    // Citizen-facing payment and refund endpoints.
    [ApiController]
    [Route("api/payments")]
    public class PaymentsController : ControllerBase
    {
        private readonly IPaymentService _paymentService;
        private readonly IStripeService _stripeService;
        private readonly IConfiguration _configuration;

        public PaymentsController(IPaymentService paymentService, IStripeService stripeService, IConfiguration configuration)
        {
            _paymentService = paymentService;
            _stripeService = stripeService;
            _configuration = configuration;
        }

        [AllowAnonymous]
        [HttpGet("bank-details")]
        public IActionResult GetBankDetails()
        {
            string Get(string key) => _configuration[key] ?? System.Environment.GetEnvironmentVariable(key) ?? "";
            return Ok(new
            {
                accountName = Get("BANK_ACCOUNT_NAME"),
                bankName = Get("BANK_NAME"),
                branchName = Get("BANK_BRANCH"),
                accountNumber = Get("BANK_ACCOUNT_NUMBER"),
            });
        }

        private int GetCurrentUserId()
        {
            var sub = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
            return int.TryParse(sub, out var id) ? id : 0;
        }

        [Authorize]
        [HttpPost("bank-transfer")]
        [RequestSizeLimit(15 * 1024 * 1024)]
        public async Task<IActionResult> CreateBankTransferPayment([FromForm] CreateBankTransferPaymentRequest request)
        {
            try
            {
                var payment = await _paymentService.CreateBankTransferPaymentAsync(GetCurrentUserId(), request);
                return Ok(payment);
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [Authorize]
        [HttpPost("stripe/create-intent")]
        public async Task<IActionResult> CreateStripeIntent([FromBody] CreateStripeIntentRequest request)
        {
            if (!_stripeService.IsConfigured)
                return BadRequest(new { message = "Online card payments are not configured yet. Please use bank transfer." });

            try
            {
                var intent = await _paymentService.CreateStripeIntentAsync(GetCurrentUserId(), request);
                return Ok(intent);
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [Authorize]
        [HttpPost("stripe/{id}/sync")]
        public async Task<IActionResult> SyncStripePayment(int id)
        {
            var payment = await _paymentService.SyncStripePaymentAsync(id, GetCurrentUserId());
            if (payment == null) return NotFound();
            return Ok(payment);
        }

        [AllowAnonymous]
        [HttpPost("stripe/webhook")]
        public async Task<IActionResult> StripeWebhook()
        {
            using var reader = new StreamReader(Request.Body);
            var json = await reader.ReadToEndAsync();

            Stripe.Event stripeEvent;
            try
            {
                stripeEvent = _stripeService.ConstructWebhookEvent(json, Request.Headers["Stripe-Signature"]);
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = $"Webhook signature verification failed: {ex.Message}" });
            }

            if (stripeEvent.Type == "payment_intent.succeeded" &&
                stripeEvent.Data.Object is Stripe.PaymentIntent intent)
            {
                await _paymentService.HandleStripePaymentSucceededAsync(intent.Id);
            }

            return Ok();
        }

        [Authorize]
        [HttpGet("my")]
        public async Task<IActionResult> GetMyPayments()
        {
            var payments = await _paymentService.GetPaymentsForUserAsync(GetCurrentUserId());
            return Ok(payments);
        }

        [Authorize]
        [HttpGet("{id}")]
        public async Task<IActionResult> GetPayment(int id)
        {
            var payment = await _paymentService.GetPaymentForUserAsync(id, GetCurrentUserId());
            if (payment == null) return NotFound();
            return Ok(payment);
        }

        [Authorize]
        [HttpGet("{id}/slip")]
        public async Task<IActionResult> GetSlip(int id)
        {
            var slip = await _paymentService.GetSlipForUserAsync(id, GetCurrentUserId());
            if (slip == null) return NotFound();
            return File(slip.Bytes, slip.ContentType, slip.FileName);
        }

        [Authorize]
        [HttpPost("{id}/refund-request")]
        public async Task<IActionResult> RequestRefund(int id, [FromBody] RequestRefundRequest request)
        {
            try
            {
                var refund = await _paymentService.RequestRefundAsync(id, GetCurrentUserId(), request);
                if (refund == null) return NotFound();
                return Ok(refund);
            }
            catch (System.Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        // ---------------- Public refund form (token-based, no login) ----------------

        [AllowAnonymous]
        [HttpGet("refunds/form/{token}")]
        public async Task<IActionResult> GetRefundForm(string token)
        {
            var form = await _paymentService.GetRefundFormAsync(token);
            if (form == null) return NotFound();
            return Ok(form);
        }

        [AllowAnonymous]
        [HttpPost("refunds/form/{token}")]
        public async Task<IActionResult> SubmitRefundForm(string token, [FromBody] SubmitRefundFormRequest request)
        {
            var success = await _paymentService.SubmitRefundFormAsync(token, request);
            if (!success) return BadRequest(new { message = "This refund link is invalid or has already been submitted." });
            return Ok(new { success = true });
        }

        [AllowAnonymous]
        [HttpGet("stripe/publishable-key")]
        public IActionResult GetPublishableKey()
        {
            return Ok(new { publishableKey = _stripeService.PublishableKey, configured = _stripeService.IsConfigured });
        }
    }
}
