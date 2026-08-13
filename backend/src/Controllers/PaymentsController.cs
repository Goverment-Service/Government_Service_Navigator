using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Services.Interfaces;

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

        [HttpPost("{id}/refund-request")]
        public async Task<IActionResult> CreateRefundRequest(int id, [FromBody] CreateRefundRequestRequest request)
        {
            if (!ModelState.IsValid)
            {
                var errors = string.Join(" ", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
                return Ok(new RefundResponse { Success = false, ErrorMessage = errors });
            }

            try
            {
                var response = await _paymentService.CreateRefundRequestAsync(id, request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return Ok(new RefundResponse { Success = false, ErrorMessage = ex.Message });
            }
        }

        [HttpGet("{id}/ledger")]
        public async Task<IActionResult> GetLedger(int id)
        {
            try
            {
                var response = await _paymentService.GetLedgerAsync(id);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return Ok(new LedgerResponse { Success = false, ErrorMessage = ex.Message });
            }
        }
    }
}
