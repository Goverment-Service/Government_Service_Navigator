using Government_Service_Navigator.AgenticAi.Tools.CalculateFee;
using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Government_Service_Navigator.AgenticAi.Agents.ValidationSafety;
using Government_Service_Navigator.AgenticAi.Schemas;

namespace Government_Service_Navigator.Backend.Controllers
{
    // Citizen-facing application intake: fetch a service's form, submit it, and (for paid services) finalize after payment.
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
        private readonly ICalculateFeeTool _feeTool;
        private readonly IValidationSafetyAgent _safetyAgent;

        public ApplicationsController(AppDbContext context, IVerificationService verificationService, ICalculateFeeTool feeTool, IValidationSafetyAgent safetyAgent)
        {
            _context = context;
            _verificationService = verificationService;
            _feeTool = feeTool;
            _safetyAgent = safetyAgent;
        }

        // Active application template linked to the service, or 404 if the admin hasn't built one.
        [HttpGet("form/{serviceProcedureId:int}")]
        public async Task<IActionResult> GetForm(int serviceProcedureId, [FromQuery] int stage = 1)
        {
            var query = _context.Templates
                .Include(t => t.Fields.OrderBy(f => f.OrderIndex))
                .Where(t => t.ServiceProcedureId == serviceProcedureId && t.Status == "Active");

            var template = await query
                .Where(t => t.StageOrder == stage)
                .OrderByDescending(t => t.CreatedAt)
                .FirstOrDefaultAsync()
                ?? await query.OrderBy(t => t.StageOrder).FirstOrDefaultAsync();

            if (template == null) return NotFound("No application form is available for this service yet.");

            var service = await _context.ServiceProcedures.FindAsync(serviceProcedureId);
            var deptName = !string.IsNullOrEmpty(template.Department) ? template.Department : null;
            var (resolvedDept, email) = await ResolveDepartmentAsync(deptName ?? service?.Category);
            return Ok(new
            {
                template,
                stage = template.StageOrder,
                totalStages = service?.TotalStages ?? 1,
                department = new { name = deptName ?? resolvedDept, email }
            });
        }

        // Returns all configured workflow stages and application forms for a service
        [HttpGet("stages/{serviceProcedureId:int}")]
        public async Task<IActionResult> GetStages(int serviceProcedureId)
        {
            var service = await _context.ServiceProcedures.FindAsync(serviceProcedureId);
            if (service == null) return NotFound("Service not found.");

            var templates = await _context.Templates
                .Where(t => t.ServiceProcedureId == serviceProcedureId && t.Status == "Active")
                .OrderBy(t => t.StageOrder)
                .Select(t => new
                {
                    t.Id,
                    t.FormName,
                    t.SubTitle,
                    t.Department,
                    t.StageOrder,
                    t.StageDescription
                })
                .ToListAsync();

            List<string> workflowDepts = new();
            if (!string.IsNullOrEmpty(service.WorkflowDepartments))
            {
                try { workflowDepts = JsonSerializer.Deserialize<List<string>>(service.WorkflowDepartments) ?? new(); }
                catch { }
            }

            return Ok(new
            {
                serviceId = service.Id,
                serviceName = service.Name,
                totalStages = service.TotalStages,
                workflowDepartments = workflowDepts,
                stageForms = templates
            });
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

        private const long MaxDocumentBytes = UploadedFileTypes.MaxBytes;

        // Uploads one supporting document (PDF / JPEG / PNG, max 10 MB) for a "file" field. The returned id is
        // sent in SubmitApplicationRequest.Documents; unattached uploads are never shown to officers.
        [HttpPost("documents")]
        [RequestSizeLimit(MaxDocumentBytes + 64 * 1024)]
        public async Task<IActionResult> UploadDocument([FromForm] UploadDocumentRequest request)
        {
            var file = request.File;
            var nic = User.FindFirstValue("nicNumber");
            if (string.IsNullOrWhiteSpace(nic)) return Forbid();

            if (file == null || file.Length == 0) return BadRequest(new { message = "Choose a file to upload." });
            if (file.Length > MaxDocumentBytes) return BadRequest(new { message = "Files must be 10 MB or smaller." });

            using var buffer = new MemoryStream();
            await file.CopyToAsync(buffer);
            var content = buffer.ToArray();

            // Decide the type from the file's bytes, not the client-supplied header
            var contentType = UploadedFileTypes.Detect(content);
            if (contentType == null) return BadRequest(new { message = "Only PDF, JPEG and PNG files are accepted." });

            var document = new SubmissionDocument
            {
                FieldLabel = request.FieldLabel?.Trim() ?? string.Empty,
                FileName = Path.GetFileName(file.FileName),
                ContentType = contentType,
                SizeBytes = content.LongLength,
                Content = content,
                UploaderNic = nic,
                UploadedAt = DateTime.UtcNow
            };
            _context.SubmissionDocuments.Add(document);
            await _context.SaveChangesAsync();

            return Ok(new { id = document.Id, fileName = document.FileName, contentType, sizeBytes = document.SizeBytes });
        }

        [HttpPost("submit")]
        public async Task<IActionResult> Submit([FromBody] SubmitApplicationRequest request)
        {
            var nic = User.FindFirstValue("nicNumber");
            if (string.IsNullOrWhiteSpace(nic)) return Forbid();

            var service = await _context.ServiceProcedures.FindAsync(request.ServiceProcedureId);
            if (service == null || service.Status == "Retired") return NotFound("Service not found.");

            // Uploaded documents: must belong to the caller and not already be attached to another application
            var documentIds = request.Documents.Values.Distinct().ToList();
            var documents = await _context.SubmissionDocuments
                .Where(d => documentIds.Contains(d.Id) && d.UploaderNic == nic && d.ApplicationId == null)
                .ToDictionaryAsync(d => d.Id);
            if (documents.Count != documentIds.Count)
                return BadRequest(new { message = "One or more uploaded documents are invalid. Please upload them again." });

            // The stored answer for a file field is the uploaded file's name
            foreach (var (label, id) in request.Documents)
                request.Answers[label] = documents[id].FileName;

            string? targetDept = null;
            int stageOrder = 1;

            if (request.TemplateId.HasValue)
            {
                var template = await _context.Templates
                    .Include(t => t.Fields)
                    .FirstOrDefaultAsync(t => t.Id == request.TemplateId.Value
                                              && t.ServiceProcedureId == request.ServiceProcedureId);
                if (template == null) return BadRequest("Form does not belong to this service.");

                targetDept = template.Department;
                stageOrder = template.StageOrder;

                var missing = template.Fields
                    .Where(f => f.IsRequired && !DisplayOnlyTypes.Contains(f.Type))
                    .Where(f => !request.Answers.TryGetValue(f.Label, out var v) || string.IsNullOrWhiteSpace(v))
                    .Select(f => f.Label)
                    .ToList();
                if (missing.Count > 0)
                    return BadRequest(new { message = "Required fields are missing.", missingFields = missing });
            }

            // Footer values are set server-side so the client can't alter which department receives it.
            var (defaultDept, departmentEmail) = await ResolveDepartmentAsync(service.Category);
            var finalDept = targetDept ?? defaultDept;
            request.Answers[PresentedByKey] = finalDept;
            request.Answers[EmailKey] = departmentEmail;

            var fee = await _feeTool.CalculateAsync(service.Id);
            var statutoryStages = fee.TotalAmount > 0 ? 3 : 2;
            var maxStages = Math.Max(service.TotalStages, statutoryStages);

            var submission = new ApplicationSubmission
            {
                ServiceProcedureId = service.Id,
                TemplateId = request.TemplateId,
                CitizenNic = nic,
                UserEmail = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty,
                FormDataJson = JsonSerializer.Serialize(request.Answers),
                SubmittedAt = DateTime.UtcNow,
                CurrentStage = stageOrder,
                MaxStages = maxStages,
                CurrentDepartment = finalDept,
                StageStatus = "PendingReview"
            };

            // 1. Build Draft Application for Agent 4
            var draft = new DraftApplication
            {
                ApplicationId = 0, // will be set upon save
                ServiceProcedureId = service.Id,
                ServiceName = service.Name,
                CitizenNic = nic,
                CitizenName = User.FindFirstValue(ClaimTypes.Name) ?? nic,
                FormFields = request.Answers,
                AttachedDocumentNames = documents.Values.Select(d => d.FileName).ToList()
            };

            // 2. Run Agent 4 (Schema, Duplicates, Risk Scoring)
            var validationResult = await _safetyAgent.ValidateAndEnqueueAsync(draft);

            if (!validationResult.IsValid)
            {
                return BadRequest(new 
                { 
                    message = "Application safety validation failed.", 
                    errors = validationResult.RejectionReasons,
                    summary = validationResult.Summary
                });
            }

            _context.ApplicationSubmissions.Add(submission);
            await _context.SaveChangesAsync();

            foreach (var (label, id) in request.Documents)
            {
                documents[id].ApplicationId = submission.Id;
                documents[id].FieldLabel = label;
            }
            if (documents.Count > 0) await _context.SaveChangesAsync();

            // Services with a fee: the application stays out of the officer queue until it is paid (see Finalize)
            if (fee.TotalAmount > 0)
                return Ok(PaymentRequiredResponse(submission, service.Name, fee));

            return Ok(await SendToVerificationAsync(submission, service.Name, nic, validationResult.ComplianceChecks));
        }

        // Called after paying: once Paid payments (or an installment plan with its first installment paid) cover
        // the fee, the application is sent to the officer queue.
        // Idempotent — returns the existing task if the application was already finalized.
        [HttpPost("{applicationId:int}/finalize")]
        public async Task<IActionResult> Finalize(int applicationId)
        {
            var nic = User.FindFirstValue("nicNumber");
            if (string.IsNullOrWhiteSpace(nic)) return Forbid();

            var submission = await _context.ApplicationSubmissions
                .Include(s => s.ServiceProcedure)
                .FirstOrDefaultAsync(s => s.Id == applicationId && s.CitizenNic == nic);
            if (submission?.ServiceProcedure == null) return NotFound("Application not found.");
            var serviceName = submission.ServiceProcedure.Name;

            var existingTask = await _context.VerificationTasks.FirstOrDefaultAsync(t => t.ApplicationId == applicationId);
            if (existingTask != null)
                return Ok(SubmittedResponse(submission, serviceName, existingTask.Id));

            var fee = await _feeTool.CalculateAsync(submission.ServiceProcedureId);
            var paid = await _context.Payments
                .Where(p => p.ApplicationId == applicationId && p.Status == "Paid")
                .SumAsync(p => (decimal?)p.Amount) ?? 0m;

            // An installment plan covering the fee counts once its first installment is paid
            var paymentIds = await _context.Payments
                .Where(p => p.ApplicationId == applicationId)
                .Select(p => p.Id)
                .ToListAsync();
            var onInstallmentPlan = await _context.InstallmentPlans
                .AnyAsync(ip => paymentIds.Contains(ip.PaymentId)
                                && (ip.Status == "Active" || ip.Status == "Completed")
                                && ip.TotalAmount >= fee.TotalAmount
                                && ip.Installments!.Any(i => i.Status == "Paid"));

            if (paid < fee.TotalAmount && !onInstallmentPlan)
                return StatusCode(StatusCodes.Status402PaymentRequired, PaymentRequiredResponse(submission, serviceName, fee, paid));

            return Ok(await SendToVerificationAsync(submission, serviceName, nic));
        }

        private async Task<object> SendToVerificationAsync(ApplicationSubmission submission, string serviceName, string nic, List<ComplianceCheckItem>? checks = null)
        {
            var task = await _verificationService.CreateTaskAsync(new CreateTaskRequest
            {
                ApplicationId = submission.Id,
                CitizenNic = nic,
                Department = submission.CurrentDepartment,
                StageNumber = submission.CurrentStage
            }, User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "Citizen");
            if (checks != null && checks.Count > 0)
            {
                foreach (var c in checks)
                {
                    _context.ComplianceChecks.Add(new ComplianceCheck
                    {
                        TaskId = task.Id,
                        CheckType = c.CheckType,
                        IsPassed = c.IsPassed,
                        Details = c.Details
                    });
                }
                await _context.SaveChangesAsync();
            }

            return SubmittedResponse(submission, serviceName, task.Id);
        }

        private static object SubmittedResponse(ApplicationSubmission submission, string serviceName, int taskId) => new
        {
            applicationId = submission.Id,
            taskId,
            referenceNumber = $"APP-{submission.Id}",
            serviceName,
            paymentRequired = false
        };

        private static object PaymentRequiredResponse(ApplicationSubmission submission, string serviceName, FeeCalculationResult fee, decimal paid = 0m) => new
        {
            applicationId = submission.Id,
            referenceNumber = $"APP-{submission.Id}",
            serviceName,
            paymentRequired = true,
            message = "Pay the service fee to submit your application.",
            amount = fee.TotalAmount - paid,
            totalFee = fee.TotalAmount,
            amountPaid = paid,
            currency = fee.Currency,
            feeItems = fee.LineItems.Select(i => new { i.FeeType, i.Amount }),
            userEmail = submission.UserEmail
        };

        // Submits the next sequential stage application form (e.g. Stage 2 for Department B)
        [HttpPost("submit-stage")]
        public async Task<IActionResult> SubmitStage([FromBody] SubmitStageRequest request)
        {
            var nic = User.FindFirstValue("nicNumber");
            if (string.IsNullOrWhiteSpace(nic)) return Forbid();

            var submission = await _context.ApplicationSubmissions
                .Include(s => s.ServiceProcedure)
                .FirstOrDefaultAsync(s => s.Id == request.ApplicationId && s.CitizenNic == nic);
            if (submission == null) return NotFound("Application not found.");

            var template = await _context.Templates
                .Include(t => t.Fields)
                .FirstOrDefaultAsync(t => t.Id == request.TemplateId && t.ServiceProcedureId == submission.ServiceProcedureId);
            if (template == null) return BadRequest("Form template does not belong to this service.");

            // Uploaded documents: must belong to the caller and not already attached
            var documentIds = request.Documents.Values.Distinct().ToList();
            var documents = await _context.SubmissionDocuments
                .Where(d => documentIds.Contains(d.Id) && d.UploaderNic == nic && d.ApplicationId == null)
                .ToDictionaryAsync(d => d.Id);

            foreach (var (label, id) in request.Documents)
            {
                if (documents.TryGetValue(id, out var doc))
                {
                    request.Answers[label] = doc.FileName;
                    doc.ApplicationId = submission.Id;
                    doc.FieldLabel = label;
                }
            }

            // Merge answers into existing form data
            Dictionary<string, string> currentAnswers = new();
            try { currentAnswers = JsonSerializer.Deserialize<Dictionary<string, string>>(submission.FormDataJson) ?? new(); }
            catch { }

            foreach (var kvp in request.Answers)
            {
                currentAnswers[$"[Stage {template.StageOrder}] {kvp.Key}"] = kvp.Value;
            }

            submission.FormDataJson = JsonSerializer.Serialize(currentAnswers);
            submission.CurrentStage = template.StageOrder;
            submission.CurrentDepartment = template.Department;
            submission.StageStatus = "PendingReview";

            // Enqueue new verification task for the new department!
            var task = await _verificationService.CreateTaskAsync(new CreateTaskRequest
            {
                ApplicationId = submission.Id,
                CitizenNic = nic,
                Department = template.Department,
                StageNumber = template.StageOrder
            }, User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "Citizen");

            await _context.SaveChangesAsync();

            return Ok(new
            {
                applicationId = submission.Id,
                taskId = task.Id,
                currentStage = submission.CurrentStage,
                department = template.Department,
                status = "PendingReview",
                message = $"Stage {template.StageOrder} application submitted for verification by {template.Department}."
            });
        }
    }

    public class SubmitStageRequest
    {
        public int ApplicationId { get; set; }
        public Guid TemplateId { get; set; }
        public Dictionary<string, string> Answers { get; set; } = new();
        public Dictionary<string, Guid> Documents { get; set; } = new();
    }
}
