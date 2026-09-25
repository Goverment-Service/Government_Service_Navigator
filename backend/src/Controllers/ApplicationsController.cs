using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Controllers
{
    // Citizen-facing application intake: fetch a service's form, then submit it.
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ApplicationsController : ControllerBase
    {
        // Layout-only template elements that never carry an answer.
        private static readonly string[] DisplayOnlyTypes = { "heading", "paragraph" };

        // Service Catalog category -> department; mirrors web/src/constants/departments.ts.
        private static readonly Dictionary<string, string> DepartmentByCategory = new(StringComparer.OrdinalIgnoreCase)
        {
            ["Police"] = "Police Department",
            ["Commerce"] = "Finance Department",
            ["Transport"] = "Transport Department",
            ["Civil"] = "Civil Department",
        };

        private const string PresentedByKey = "Presented by";
        private const string EmailKey = "Email";

        private readonly AppDbContext _context;
        private readonly IVerificationService _verificationService;

        public ApplicationsController(AppDbContext context, IVerificationService verificationService)
        {
            _context = context;
            _verificationService = verificationService;
        }

        // Active application template linked to the service, or 404 if the admin hasn't built one.
        [HttpGet("form/{serviceProcedureId}")]
        public async Task<IActionResult> GetForm(int serviceProcedureId)
        {
            var template = await _context.Templates
                .Include(t => t.Fields.OrderBy(f => f.OrderIndex))
                .Where(t => t.ServiceProcedureId == serviceProcedureId && t.Status == "Active")
                .OrderByDescending(t => t.CreatedAt)
                .FirstOrDefaultAsync();

            if (template == null) return NotFound("No application form is available for this service yet.");

            var service = await _context.ServiceProcedures.FindAsync(serviceProcedureId);
            var (department, email) = await ResolveDepartmentAsync(service?.Category);
            return Ok(new { template, department = new { name = department, email } });
        }

        // The department handling a service category, and the email of its active Department Admin.
        private async Task<(string Name, string Email)> ResolveDepartmentAsync(string? category)
        {
            var name = category != null && DepartmentByCategory.TryGetValue(category, out var dept)
                ? dept
                : string.IsNullOrWhiteSpace(category) ? "General" : category;

            var email = await _context.Officers
                .Where(o => o.Department == name && o.Role == "Department Admin" && o.Status == "Active")
                .OrderBy(o => o.CreatedAt)
                .Select(o => o.Email)
                .FirstOrDefaultAsync();

            return (name, email ?? string.Empty);
        }

        [HttpPost("submit")]
        public async Task<IActionResult> Submit([FromBody] SubmitApplicationRequest request)
        {
            var nic = User.FindFirstValue("nicNumber");
            if (string.IsNullOrWhiteSpace(nic)) return Forbid();

            var service = await _context.ServiceProcedures.FindAsync(request.ServiceProcedureId);
            if (service == null || service.Status == "Retired") return NotFound("Service not found.");

            if (request.TemplateId.HasValue)
            {
                var template = await _context.Templates
                    .Include(t => t.Fields)
                    .FirstOrDefaultAsync(t => t.Id == request.TemplateId.Value
                                              && t.ServiceProcedureId == request.ServiceProcedureId);
                if (template == null) return BadRequest("Form does not belong to this service.");

                var missing = template.Fields
                    .Where(f => f.IsRequired && !DisplayOnlyTypes.Contains(f.Type))
                    .Where(f => !request.Answers.TryGetValue(f.Label, out var v) || string.IsNullOrWhiteSpace(v))
                    .Select(f => f.Label)
                    .ToList();
                if (missing.Count > 0)
                    return BadRequest(new { message = "Required fields are missing.", missingFields = missing });
            }

            // Footer values are set server-side so the client can't alter which department receives it.
            var (department, departmentEmail) = await ResolveDepartmentAsync(service.Category);
            request.Answers[PresentedByKey] = department;
            request.Answers[EmailKey] = departmentEmail;

            var submission = new ApplicationSubmission
            {
                ServiceProcedureId = service.Id,
                TemplateId = request.TemplateId,
                CitizenNic = nic,
                UserEmail = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty,
                FormDataJson = JsonSerializer.Serialize(request.Answers),
                SubmittedAt = DateTime.UtcNow
            };
            _context.ApplicationSubmissions.Add(submission);
            await _context.SaveChangesAsync();

            var task = await _verificationService.CreateTaskAsync(new CreateTaskRequest
            {
                ApplicationId = submission.Id,
                CitizenNic = nic
            }, User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "Citizen");

            return Ok(new
            {
                applicationId = submission.Id,
                taskId = task.Id,
                referenceNumber = $"APP-{submission.Id}",
                serviceName = service.Name
            });
        }
    }
}
