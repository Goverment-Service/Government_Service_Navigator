using Microsoft.AspNetCore.Mvc;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.DTOs;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ServicesController : ControllerBase
    {
        private readonly IServiceCatalogService _catalogService;

        public ServicesController(IServiceCatalogService catalogService)
        {
            _catalogService = catalogService;
        }

       // Admin adds a new service/procedure
[HttpPost]
public async Task<IActionResult> CreateService([FromBody] ServiceProcedure service)
{
    try
    {
        var createdService = await _catalogService.CreateServiceAsync(service);
        return CreatedAtAction(nameof(GetService), new { id = createdService.Id }, createdService);
    }
    catch (Exception ex)
    {
        return StatusCode(500, new { message = ex.Message, inner = ex.InnerException?.Message });
    }
}


        // Fetch procedure details + document checklist
        [HttpGet("{id}")]
        public async Task<IActionResult> GetService(int id)
        {
            var service = await _catalogService.GetServiceByIdAsync(id);
            if (service == null) return NotFound();
            return Ok(service);
        }

        // List all services for the Catalog Manager UI
        [HttpGet]
        public async Task<IActionResult> GetAllServices()
        {
            var services = await _catalogService.GetAllServicesAsync();
            return Ok(services);
        }

        // Update eligibility criteria for a service
        [HttpPut("{id}/eligibility-rules")]
        public async Task<IActionResult> UpdateEligibilityRules(int id, [FromBody] List<EligibilityRule> rules)
        {
            try
            {
                var updatedService = await _catalogService.UpdateEligibilityRulesAsync(id, rules);
                return Ok(updatedService);
            }
            catch (KeyNotFoundException)
            {
                return NotFound("Service procedure not found.");
            }
        }

        // Retire/deactivate a procedure
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteService(int id)
        {
            var success = await _catalogService.RetireServiceAsync(id);
            if (!success) return NotFound();
            return NoContent();
        }

        // Update basic details of an existing service
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateService(int id, [FromBody] ServiceProcedure updatedService)
        {
            var service = await _catalogService.UpdateServiceAsync(id, updatedService);
            if (service == null) return NotFound("Service procedure not found.");

            return Ok(service);
        }


        // Scores a citizen profile against a service's rules; returns match % + missing criteria
        [HttpPost("eligibility-score")]
        public async Task<IActionResult> CalculateEligibilityScore([FromBody] EligibilityRequestDto request)
        {
            try
            {
                var result = await _catalogService.CalculateEligibilityScoreAsync(request.ServiceId, request.CitizenProfile);
                return Ok(result);
            }
            catch (KeyNotFoundException)
            {
                return NotFound("Service procedure not found.");
            }
        }

        // Update document requirements for a service
        [HttpPut("{id}/documents")]
        public async Task<IActionResult> UpdateDocumentRequirements(int id, [FromBody] List<DocumentRequirement> documents)
        {
            try
            {
                var updatedService = await _catalogService.UpdateDocumentRequirementsAsync(id, documents);
                return Ok(updatedService);
            }
            catch (KeyNotFoundException)
            {
                return NotFound("Service procedure not found.");
            }
        }
        // Delete a specific document requirement by its ID
        [HttpDelete("documents/{documentId}")]
        public async Task<IActionResult> DeleteDocumentRequirement(int documentId)
        {
            var success = await _catalogService.DeleteDocumentRequirementAsync(documentId);
            if (!success) return NotFound("Document requirement not found.");

            return NoContent();
        }

        

        [HttpPut("{id}/fees")]
        public async Task<IActionResult> UpdateFeeSchedules(int id, [FromBody] List<FeeSchedule> fees)
        {
            try
            {
                var updatedService = await _catalogService.UpdateFeeSchedulesAsync(id, fees);
                return Ok(updatedService);
            }
            catch (KeyNotFoundException)
            {
                return NotFound("Service procedure not found.");
            }
        }

        [HttpDelete("fees/{feeId}")]
        public async Task<IActionResult> DeleteFeeSchedule(int feeId)
        {
            var success = await _catalogService.DeleteFeeScheduleAsync(feeId);
            if (!success) return NotFound("Fee schedule not found.");
            return NoContent();
        }

        // Configure multi-department stages and workflow for a service
        [HttpPut("{id}/workflow")]
        public async Task<IActionResult> UpdateWorkflow(int id, [FromBody] UpdateWorkflowRequest request)
        {
            var updated = await _catalogService.UpdateWorkflowAsync(id, request.TotalStages, request.WorkflowDepartments);
            if (updated == null) return NotFound("Service procedure not found.");
            return Ok(updated);
        }
    }

    public class UpdateWorkflowRequest
    {
        public int TotalStages { get; set; } = 1;
        public List<string> WorkflowDepartments { get; set; } = new();
    }
}
