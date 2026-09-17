using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api")]
    public class InstallmentPlansController : ControllerBase
    {
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

        [HttpPost("installment-plans/installments/{installmentId}/pay")]
        [Authorize]
        public async Task<IActionResult> MarkPaid(int installmentId)
        {
            try
            {
                var installment = await _installmentPlanService.MarkInstallmentPaidAsync(installmentId);
                return Ok(installment);
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
            catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        }
    }
}