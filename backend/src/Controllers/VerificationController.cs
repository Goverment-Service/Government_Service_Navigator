using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // Require JWT token
    public class VerificationController : ControllerBase
    {
        // Every staff role that can sign in to the web portal; citizens ("User") are excluded.
        private const string OfficerRoles =
            "Verifying Officer,Department Admin,Auditor,Finance Officer,Officer,Admin,System Admin";

        private readonly IVerificationService _verificationService;
        private readonly AppDbContext _context;
        private readonly IApplicationDraftingService _draftingService;

        public VerificationController(
            IVerificationService verificationService,
            AppDbContext context,
            IApplicationDraftingService draftingService)
        {
            _verificationService = verificationService;
            _context = context;
            _draftingService = draftingService;
        }

        // Officer queue rows: each task joined to its submitted application, service and citizen.
        private async Task<List<object>> WithApplicationDetailsAsync(List<VerificationTask> tasks)
        {
            var appIds = tasks.Select(t => t.ApplicationId).ToList();
            var submissions = await _context.ApplicationSubmissions
                .Where(s => appIds.Contains(s.Id))
                .Select(s => new { s.Id, s.CitizenNic, ServiceName = s.ServiceProcedure!.Name, s.ServiceProcedure.Category })
                .ToDictionaryAsync(s => s.Id);

            var nics = submissions.Values.Select(s => s.CitizenNic)
                .Concat(tasks.Select(t => t.CitizenNic ?? string.Empty))
                .Where(n => n != string.Empty)
                .Distinct()
                .ToList();
            var names = await _context.Users
                .Where(u => nics.Contains(u.NicNumber))
                .GroupBy(u => u.NicNumber)
                .Select(g => new { Nic = g.Key, g.First().FullName })
                .ToDictionaryAsync(u => u.Nic, u => u.FullName);

            return tasks.Select(t =>
            {
                submissions.TryGetValue(t.ApplicationId, out var s);
                var nic = s?.CitizenNic ?? t.CitizenNic;
                return (object)new
                {
                    t.Id,
                    t.ApplicationId,
                    t.Status,
                    t.CreatedDate,
                    t.CurrentStage,
                    t.MaxStages,
                    ReferenceNumber = $"APP-{t.ApplicationId}",
                    CitizenNic = nic,
                    CitizenName = nic != null && names.TryGetValue(nic, out var name) ? name : null,
                    ServiceName = s?.ServiceName,
                    Category = s?.Category
                };
            }).ToList();
        }

        // The "sub" JWT claim is inbound-mapped to ClaimTypes.NameIdentifier by the JWT bearer
        // handler; User.Identity.Name (ClaimTypes.Name) is never set, so it always reads null.
        private string GetCurrentOfficerId() =>
            User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.Identity?.Name ?? "Unknown";

        // Citizen view: only the applications submitted under the caller's own NIC.
        [HttpGet("my-applications")]
        public async Task<IActionResult> GetMyApplications()
        {
            var nic = User.FindFirstValue("nicNumber");
            if (string.IsNullOrWhiteSpace(nic)) return Ok(Array.Empty<object>());

            var tasks = await _verificationService.GetTasksForCitizenAsync(nic);

            // Attach the service name/department from the citizen's submissions so the app can label each entry.
            var appIds = tasks.Select(t => t.ApplicationId).ToList();
            var services = await _context.ApplicationSubmissions
                .Where(s => appIds.Contains(s.Id) && s.CitizenNic == nic)
                .Select(s => new { s.Id, s.ServiceProcedure!.Name, s.ServiceProcedure.Category })
                .ToDictionaryAsync(s => s.Id);

            // Latest installment plan per application, so the app can open its schedule from the application card
            var plans = await _context.InstallmentPlans
                .Where(p => appIds.Contains(p.Payment!.ApplicationId))
                .Select(p => new
                {
                    p.Id,
                    p.Payment!.ApplicationId,
                    p.Status,
                    p.NumberOfInstallments,
                    PaidCount = p.Installments!.Count(i => i.Status == "Paid"),
                    Next = p.Installments!
                        .Where(i => i.Status != "Paid")
                        .OrderBy(i => i.InstallmentNumber)
                        .Select(i => new { i.Amount, i.DueDate, i.Status })
                        .FirstOrDefault()
                })
                .ToListAsync();
            var planByApp = plans
                .GroupBy(p => p.ApplicationId)
                .ToDictionary(g => g.Key, g => g.OrderByDescending(p => p.Id).First());

            return Ok(tasks.Select(t => new
            {
                t.Id,
                t.ApplicationId,
                t.Status,
                t.CreatedDate,
                ReferenceNumber = $"APP-{t.ApplicationId}",
                ServiceName = services.TryGetValue(t.ApplicationId, out var s) ? s.Name : null,
                Category = s?.Category,
                InstallmentPlan = planByApp.TryGetValue(t.ApplicationId, out var plan)
                    ? new
                    {
                        PlanId = plan.Id,
                        plan.Status,
                        plan.NumberOfInstallments,
                        plan.PaidCount,
                        NextAmount = plan.Next?.Amount,
                        NextDueDate = plan.Next?.DueDate,
                        NextStatus = plan.Next?.Status
                    }
                    : null
            }));
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpGet("tasks/pending")]
        public async Task<IActionResult> GetPendingTasks()
        {
            var tasks = await _verificationService.GetPendingTasksAsync();
            return Ok(await WithApplicationDetailsAsync(tasks));
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpGet("tasks/verified")]
        public async Task<IActionResult> GetVerifiedTasks()
        {
            var tasks = await _verificationService.GetVerifiedTasksAsync();
            return Ok(await WithApplicationDetailsAsync(tasks));
        }

        // Review workspace: the task plus the citizen's submitted form answers.
        [Authorize(Roles = OfficerRoles)]
        [HttpGet("tasks/{id:int}")]
        public async Task<IActionResult> GetTaskDetail(int id)
        {
            var task = await _context.VerificationTasks.FindAsync(id);
            if (task == null) return NotFound();

            var summary = (await WithApplicationDetailsAsync(new List<VerificationTask> { task }))[0];
            var submission = await _context.ApplicationSubmissions.FindAsync(task.ApplicationId);

            Dictionary<string, string> answers = new();
            if (submission != null)
            {
                try { answers = JsonSerializer.Deserialize<Dictionary<string, string>>(submission.FormDataJson) ?? new(); }
                catch (JsonException) { }
            }

            // Metadata only; the officer fetches each file's bytes from documents/{id}/content
            var documents = await _context.SubmissionDocuments
                .Where(d => d.ApplicationId == task.ApplicationId)
                .OrderBy(d => d.UploadedAt)
                .Select(d => new { d.Id, d.FieldLabel, d.FileName, d.ContentType, d.SizeBytes, d.UploadedAt })
                .ToListAsync();

            return Ok(new
            {
                task = summary,
                submittedAt = submission?.SubmittedAt,
                userEmail = submission?.UserEmail,
                answers,
                documents
            });
        }

        // The file a citizen uploaded, streamed with its detected content type for in-browser preview.
        [Authorize(Roles = OfficerRoles)]
        [HttpGet("documents/{documentId:guid}/content")]
        public async Task<IActionResult> GetDocumentContent(Guid documentId)
        {
            var document = await _context.SubmissionDocuments
                .FirstOrDefaultAsync(d => d.Id == documentId && d.ApplicationId != null);
            if (document == null) return NotFound("Document not found.");

            // No file name here so the browser shows it inline instead of downloading it
            Response.Headers["X-Content-Type-Options"] = "nosniff";
            return File(document.Content, document.ContentType);
        }

        // Agent 3 (Action/Tool Agent) draft for the task's application: pre-filled fields, fee,
        // proposed appointment, plus Agent 2's eligibility result. 404 until it has been generated.
        [Authorize(Roles = OfficerRoles)]
        [HttpGet("tasks/{id:int}/agent-draft")]
        public async Task<IActionResult> GetAgentDraft(int id)
        {
            var task = await _context.VerificationTasks.FindAsync(id);
            if (task == null) return NotFound("Task not found.");

            var draft = await _draftingService.GetStoredDraftAsync(task.ApplicationId);
            return draft == null ? NotFound("No agent draft yet.") : Ok(draft);
        }

        // Runs Agent 2 then Agent 3 on the submitted application and stores the result.
        [Authorize(Roles = OfficerRoles)]
        [HttpPost("tasks/{id:int}/agent-draft")]
        public async Task<IActionResult> GenerateAgentDraft(int id)
        {
            var task = await _context.VerificationTasks.FindAsync(id);
            if (task == null) return NotFound("Task not found.");

            try
            {
                var draft = await _draftingService.GenerateDraftAsync(task.ApplicationId);
                return draft == null
                    ? NotFound("No submitted application is linked to this task.")
                    : Ok(draft);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Agent draft generation failed", details = ex.Message });
            }
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpGet("stats")]
        public async Task<IActionResult> GetOfficerStats()
        {
            var stats = await _verificationService.GetOfficerStatsAsync(GetCurrentOfficerId());
            return Ok(stats);
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpPost("tasks")]
        public async Task<IActionResult> CreateVerificationTask([FromBody] CreateTaskRequest request)
        {
            var task = await _verificationService.CreateTaskAsync(request, GetCurrentOfficerId());
            return Ok(task);
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpGet("audit-logs")]
        public async Task<IActionResult> GetAuditLogs([FromQuery] int applicationId)
        {
            var logs = await _verificationService.GetAuditLogsAsync(applicationId);
            return Ok(logs);
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpGet("audit-logs/all")]
        public async Task<IActionResult> GetAllAuditLogs()
        {
            var logs = await _verificationService.GetAllAuditLogsAsync();
            return Ok(logs);
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpPut("tasks/{id}/decision")]
        public async Task<IActionResult> RecordDecision(int id, [FromBody] VerificationDecisionRequest request)
        {
            var result = await _verificationService.RecordDecisionAsync(id, request, GetCurrentOfficerId());

            if (!result) return NotFound("Task not found or update failed");
            return Ok();
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpDelete("tasks/{id}")]
        public async Task<IActionResult> DeleteTask(int id)
        {
            var result = await _verificationService.DeleteTaskAsync(id, GetCurrentOfficerId());

            if (!result) return NotFound();
            return NoContent();
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpPost("tasks/bulk-verify")]
        public async Task<IActionResult> BulkVerify([FromBody] BulkVerifyRequest request)
        {
            var result = await _verificationService.BulkVerifyAsync(request, GetCurrentOfficerId());

            if (!result) return BadRequest("Bulk verification failed");
            return Ok();
        }
        [Authorize(Roles = OfficerRoles)]
        [HttpGet("rejection-reasons")]
        public async Task<IActionResult> GetRejectionReasons()
        {
            var reasons = await _verificationService.GetRejectionReasonsAsync();
            return Ok(reasons);
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpPost("rejection-reasons")]
        public async Task<IActionResult> CreateRejectionReason([FromBody] Government_Service_Navigator.Backend.Models.Entities.RejectionReason reason)
        {
            var created = await _verificationService.CreateRejectionReasonAsync(reason);
            return Ok(created);
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpPut("rejection-reasons/{id}")]
        public async Task<IActionResult> UpdateRejectionReason(int id, [FromBody] Government_Service_Navigator.Backend.Models.Entities.RejectionReason reason)
        {
            var success = await _verificationService.UpdateRejectionReasonAsync(id, reason);
            if (!success) return NotFound();
            return Ok();
        }

        [Authorize(Roles = OfficerRoles)]
        [HttpPut("tasks/{id}/approve-stage")]
        public async Task<IActionResult> ApproveStage(int id, [FromBody] ApproveStageRequest request)
        {
            var task = await _context.VerificationTasks.FindAsync(id);
            if (task == null) return NotFound("Task not found.");

            var submission = await _context.ApplicationSubmissions.FindAsync(task.ApplicationId);
            if (submission == null) return NotFound("Submission not found.");

            var officerId = GetCurrentOfficerId();

            // 1. Advance the stage
            if (task.CurrentStage < task.MaxStages)
            {
                task.CurrentStage++;
                task.Status = "Pending"; // Next stage is now pending citizen action or next review
                submission.CurrentStage = task.CurrentStage;
                submission.StageStatus = "StageApproved"; // Unlocks the next form for the citizen!
            }
            else
            {
                // All stages finished
                task.Status = "Approved";
                submission.StageStatus = "Completed";
            }

            // 2. Audit log the milestone approval
            _context.AuditLogs.Add(new AuditLog
            {
                ApplicationId = submission.Id,
                Action = $"Stage {task.CurrentStage - 1} Milestone Approved",
                PerformedBy = officerId,
                Timestamp = DateTime.UtcNow,
                OldValues = $"Stage: {task.CurrentStage - 1}",
                NewValues = $"Stage: {task.CurrentStage}, Note: {request.Notes}"
            });

            // 3. Trigger citizen notification
            var notificationService = HttpContext.RequestServices.GetService<INotificationService>();
            if (notificationService != null && !string.IsNullOrEmpty(submission.UserEmail))
            {
                await notificationService.SendEmailAsync(
                    submission.UserEmail,
                    $"Stage {task.CurrentStage - 1} Approved!",
                    $"Your Stage {task.CurrentStage - 1} documents were verified. Please open the app to complete Stage {task.CurrentStage}."
                );
            }

            await _context.SaveChangesAsync();
            return Ok(new { currentStage = task.CurrentStage, maxStages = task.MaxStages, status = task.Status });
        }

        public class ApproveStageRequest
        {
            public string? Notes { get; set; }
        }


        [Authorize(Roles = OfficerRoles)]
        [HttpDelete("rejection-reasons/{id}")]
        public async Task<IActionResult> DeleteRejectionReason(int id)
        {
            var success = await _verificationService.DeleteRejectionReasonAsync(id);
            if (!success) return NotFound();
            return NoContent();
        }
        [AllowAnonymous]
        [HttpGet("seed")]
        public async Task<IActionResult> SeedTasks()
        {
            var db = HttpContext.RequestServices.GetRequiredService<Government_Service_Navigator.Backend.Data.Context.AppDbContext>();
            var random = new Random();
            for (int i = 0; i < 5; i++)
            {
                db.VerificationTasks.Add(new Government_Service_Navigator.Backend.Models.Entities.VerificationTask
                {
                    ApplicationId = random.Next(1000, 9999),
                    Status = "Pending",
                    CreatedDate = DateTime.UtcNow.AddHours(-random.Next(1, 48))
                });
            }
            await db.SaveChangesAsync();
            return Ok("5 new Pending tasks seeded! Go back to Pending Reviews page and refresh.");
        }
    }
}
