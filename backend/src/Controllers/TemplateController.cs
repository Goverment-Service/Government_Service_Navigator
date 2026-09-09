using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api/templates")]
    public class TemplateController : ControllerBase
    {
        private readonly ITemplateService _templateService;
        public TemplateController(ITemplateService templateService) 
        {
            _templateService = templateService;
        }
        [HttpPost("create")]
        public async Task<IActionResult>CreateTemplate([FromBody] CreateTemplateRequest request) 
        {
            if(!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }
            try {
                var template = await _templateService.CreateTemplateAsync(request);
                return CreatedAtAction(nameof(GetTemplateById), new { id = template.Id }, template);
            }
            catch (Exception ex) {
                return StatusCode(500, new {
                    message = "An error occurred while creating the template.",
                    details = ex.Message
                });
            }
        }
        [HttpGet("all")]
        public async Task<IActionResult>GetAllTemplates()
        {
            var templates = await _templateService.GetAllTemplatesAsync();
            return Ok(templates);
        }
        [HttpGet("{id}")]
        public async Task<IActionResult>GetTemplateById(Guid id) 
        {
            var template = await _templateService.GetTemplateByIdAsync(id);
            if(template ==null) return NotFound();
            return Ok(template);
        }
        [HttpPut("update/{id}")]
        public async Task<IActionResult>UpdateTemplate(Guid id, [FromBody] CreateTemplateRequest request)
        {
            if(!ModelState.IsValid) return BadRequest(ModelState);
            try {
                var template = await _templateService.UpdateTemplateAsync(id, request);
                return Ok(template);
            } catch (Exception ex) {
                return StatusCode(500, new { message = ex.Message });
            }
        }
        [HttpPatch("{id}/status")]
        public async Task<IActionResult>UpdateTemplateStatus(Guid id, [FromBody] UpdateTemplateStatusRequest request)
        {
            if(!ModelState.IsValid) return BadRequest(ModelState);
            try {
                var template = await _templateService.UpdateTemplateStatusAsync(id, request.Status);
                return Ok(template);
            } catch (ArgumentException ex) {
                return BadRequest(new { message = ex.Message });
            } catch (Exception ex) {
                return StatusCode(500, new { message = ex.Message });
            }
        }
    }
}