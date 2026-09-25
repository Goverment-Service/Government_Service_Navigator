using System.Security.Claims;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Services;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api")]
    public class InstallmentPlansController : ControllerBase
    {
        // Staff who can approve payments; citizens ("User") pay through online checkout or bank transfer instead.
        private const string StaffRoles =
            "Finance Officer,Department Admin,Verifying Officer,Officer,Admin,System Admin";

        private readonly IInstallmentPlanService _installmentPlanService;

        public InstallmentPlansController(IInstallmentPlanService installmentPlanService)
        {
            _installmentPlanService = installmentPlanService;
        }

        // Matches the task-doc's required route: PUT /api/payments/{id}/installment-plan
        [HttpPut("payments/{id}/installment-plan")]
        [Authorize]
        public async Task<IActionResult> CreatePlan(int id, [FromBody] CreateInstallmentPlanDto dto)
        {
            try
            {
                var plan = await _installmentPlanService.CreatePlanAsync(id, dto.NumberOfInstallments, dto.IntervalDays);
                var response = await _installmentPlanService.GetByIdAsync(plan.Id);
                return Ok(response);
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
            catch (ArgumentException ex) { return BadRequest(ex.Message); }
            catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        }

        [HttpGet("installment-plans/{id}")]
        [Authorize]
        public async Task<IActionResult> GetById(int id)
        {
            var plan = await _installmentPlanService.GetByIdAsync(id);
            if (plan == null) return NotFound();
            return Ok(plan);
        }

        // Staff: mark an installment paid (e.g. approving a bank transfer receipt).
        [HttpPost("installment-plans/installments/{installmentId}/pay")]
        [Authorize(Roles = StaffRoles)]
        public async Task<IActionResult> MarkPaid(int installmentId)
        {
            try
            {
                var installment = await _installmentPlanService.MarkInstallmentPaidAsync(installmentId);
                return Ok(InstallmentDto.FromEntity(installment));
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
            catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        }

        // Citizen, online: starts a Stripe Checkout for exactly this installment's amount.
        [HttpPost("installment-plans/installments/{installmentId}/checkout")]
        [Authorize]
        public async Task<IActionResult> Checkout(int installmentId)
        {
            if (!await IsOwnerAsync(installmentId)) return NotFound("Installment not found.");
            try
            {
                var checkoutUrl = await _installmentPlanService.CreateOnlineCheckoutAsync(installmentId);
                return Ok(new { checkoutUrl });
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
            catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        }

        // Citizen, online: after the checkout page closes, verify with Stripe and mark the installment paid.
        [HttpPost("installment-plans/installments/{installmentId}/confirm")]
        [Authorize]
        public async Task<IActionResult> ConfirmCheckout(int installmentId)
        {
            if (!await IsOwnerAsync(installmentId)) return NotFound("Installment not found.");
            try
            {
                var installment = await _installmentPlanService.ConfirmOnlineCheckoutAsync(installmentId);
                return Ok(InstallmentDto.FromEntity(installment));
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
            catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        }

        // Citizen, bank transfer: the account to transfer into (configured in .env).
        [HttpGet("installment-plans/bank-details")]
        [Authorize]
        public IActionResult GetBankDetails() => Ok(new
        {
            accountName = Environment.GetEnvironmentVariable("BANK_ACCOUNT_NAME") ?? string.Empty,
            bankName = Environment.GetEnvironmentVariable("BANK_NAME") ?? string.Empty,
            branch = Environment.GetEnvironmentVariable("BANK_BRANCH") ?? string.Empty,
            accountNumber = Environment.GetEnvironmentVariable("BANK_ACCOUNT_NUMBER") ?? string.Empty
        });

        // Citizen, bank transfer: upload the transfer receipt (PDF / JPEG / PNG, max 10 MB); staff then verify it.
        [HttpPost("installment-plans/installments/{installmentId}/bank-transfer")]
        [Authorize]
        [RequestSizeLimit(UploadedFileTypes.MaxBytes + 64 * 1024)]
        public async Task<IActionResult> SubmitBankTransfer(int installmentId, [FromForm] UploadReceiptRequest request)
        {
            if (!await IsOwnerAsync(installmentId)) return NotFound("Installment not found.");

            var file = request.Receipt;
            if (file == null || file.Length == 0) return BadRequest(new { message = "Attach the transfer receipt." });
            if (file.Length > UploadedFileTypes.MaxBytes) return BadRequest(new { message = "Receipts must be 10 MB or smaller." });

            using var buffer = new MemoryStream();
            await file.CopyToAsync(buffer);
            var content = buffer.ToArray();
            var contentType = UploadedFileTypes.Detect(content);
            if (contentType == null) return BadRequest(new { message = "Only PDF, JPEG and PNG receipts are accepted." });

            try
            {
                var installment = await _installmentPlanService.SubmitBankTransferAsync(
                    installmentId, Path.GetFileName(file.FileName), contentType, content);
                return Ok(InstallmentDto.FromEntity(installment));
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
            catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        }

        // Staff: reject a bank transfer receipt; the installment becomes payable again.
        [HttpPost("installment-plans/installments/{installmentId}/reject-transfer")]
        [Authorize(Roles = StaffRoles)]
        public async Task<IActionResult> RejectBankTransfer(int installmentId)
        {
            try
            {
                var installment = await _installmentPlanService.RejectBankTransferAsync(installmentId);
                return Ok(InstallmentDto.FromEntity(installment));
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
            catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        }

        // Staff: the uploaded receipt, served inline for preview.
        [HttpGet("installment-plans/installments/{installmentId}/receipt")]
        [Authorize(Roles = StaffRoles)]
        public async Task<IActionResult> GetReceipt(int installmentId)
        {
            var receipt = await _installmentPlanService.GetReceiptAsync(installmentId);
            if (receipt == null) return NotFound("No receipt for this installment.");

            Response.Headers["X-Content-Type-Options"] = "nosniff";
            return File(receipt.Content, receipt.ContentType);
        }

        [HttpPost("installment-plans/{id}/cancel")]
        [Authorize]
        public async Task<IActionResult> Cancel(int id)
        {
            try
            {
                var plan = await _installmentPlanService.CancelPlanAsync(id);
                return Ok(plan);
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
            catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        }

        private Task<bool> IsOwnerAsync(int installmentId) =>
            _installmentPlanService.BelongsToCitizenAsync(
                installmentId,
                User.FindFirstValue("nicNumber"),
                User.FindFirstValue(ClaimTypes.Email) ?? User.FindFirstValue("email"));
    }
}
