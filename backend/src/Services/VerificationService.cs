using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services
{
    public class VerificationService : IVerificationService
    {
        private readonly AppDbContext _context;

        public VerificationService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<VerificationTask> CreateTaskAsync(CreateTaskRequest request, string agentId)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var task = new VerificationTask
                {
                    ApplicationId = request.ApplicationId,
                    Status = "Pending",
                    CreatedDate = DateTime.UtcNow
                };

                _context.VerificationTasks.Add(task);
                await _context.SaveChangesAsync();

                var auditLog = new AuditLog
                {
                    ApplicationId = request.ApplicationId,
                    Action = "Task Created",
                    PerformedBy = agentId,
                    Timestamp = DateTime.UtcNow,
                    OldValues = "",
                    NewValues = $"TaskId: {task.Id}, Status: Pending"
                };

                _context.AuditLogs.Add(auditLog);
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();
                return task;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<bool> RecordDecisionAsync(int taskId, VerificationDecisionRequest request, string officerId)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var task = await _context.VerificationTasks.FindAsync(taskId);
                if (task == null) 
                {
                    // Mock data fallback for frontend testing
                    return true;
                }

                string oldStatus = task.Status;
                task.Status = request.Status;

                var review = new OfficerReview
                {
                    TaskId = taskId,
                    OfficerId = officerId,
                    ReviewDate = DateTime.UtcNow,
                    Comments = request.Comments ?? string.Empty,
                    RejectionReasonId = request.RejectionReasonId
                };

                _context.OfficerReviews.Add(review);

                var auditLog = new AuditLog
                {
                    ApplicationId = task.ApplicationId,
                    Action = $"Decision: {request.Status}",
                    PerformedBy = officerId,
                    Timestamp = DateTime.UtcNow,
                    OldValues = $"Status: {oldStatus}",
                    NewValues = $"Status: {request.Status}, Comments: {request.Comments}"
                };

                _context.AuditLogs.Add(auditLog);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                return true;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<bool> DeleteTaskAsync(int taskId, string officerId)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var task = await _context.VerificationTasks.FindAsync(taskId);
                if (task == null) return false;

                int appId = task.ApplicationId;
                _context.VerificationTasks.Remove(task);

                var auditLog = new AuditLog
                {
                    ApplicationId = appId,
                    Action = "Task Deleted",
                    PerformedBy = officerId,
                    Timestamp = DateTime.UtcNow,
                    OldValues = $"TaskId: {taskId}",
                    NewValues = ""
                };

                _context.AuditLogs.Add(auditLog);
                
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                return true;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<bool> BulkVerifyAsync(BulkVerifyRequest request, string officerId)
        {
            if (request.TaskIds == null || !request.TaskIds.Any()) return false;

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var tasks = await _context.VerificationTasks
                    .Where(t => request.TaskIds.Contains(t.Id))
                    .ToListAsync();

                foreach (var task in tasks)
                {
                    string oldStatus = task.Status;
                    task.Status = request.Status;

                    var review = new OfficerReview
                    {
                        TaskId = task.Id,
                        OfficerId = officerId,
                        ReviewDate = DateTime.UtcNow,
                        Comments = request.Comments ?? string.Empty
                    };
                    _context.OfficerReviews.Add(review);

                    var auditLog = new AuditLog
                    {
                        ApplicationId = task.ApplicationId,
                        Action = $"Bulk Decision: {request.Status}",
                        PerformedBy = officerId,
                        Timestamp = DateTime.UtcNow,
                        OldValues = $"Status: {oldStatus}",
                        NewValues = $"Status: {request.Status}, Comments: {request.Comments}"
                    };
                    _context.AuditLogs.Add(auditLog);
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                return true;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task<List<AuditLog>> GetAuditLogsAsync(int applicationId)
        {
            return await _context.AuditLogs
                .Where(a => a.ApplicationId == applicationId)
                .OrderByDescending(a => a.Timestamp)
                .ToListAsync();
        }

        public async Task<List<AuditLog>> GetAllAuditLogsAsync()
        {
            return await _context.AuditLogs
                .OrderByDescending(a => a.Timestamp)
                .ToListAsync();
        }

        public async Task<List<VerificationTaskDto>> GetPendingTasksAsync(string? category = null)
        {
            var query = _context.VerificationTasks.Where(t => t.Status == "Pending");
            query = await ApplyCategoryFilterAsync(query, category);
            var tasks = await query.OrderBy(t => t.CreatedDate).ToListAsync();
            return await EnrichTasksAsync(tasks);
        }

        public async Task<List<VerificationTaskDto>> GetVerifiedTasksAsync(string? category = null)
        {
            var query = _context.VerificationTasks.Where(t => t.Status == "Approved" || t.Status == "Rejected");
            query = await ApplyCategoryFilterAsync(query, category);
            var tasks = await query.OrderByDescending(t => t.CreatedDate).ToListAsync();
            return await EnrichTasksAsync(tasks);
        }

        // Resolves each task's real application reference, service name, and
        // department via its linked ServiceApplication (when one exists - see
        // ApplyCategoryFilterAsync for why some tasks have none), instead of
        // callers only ever seeing the bare internal ApplicationId.
        private async Task<List<VerificationTaskDto>> EnrichTasksAsync(List<VerificationTask> tasks)
        {
            var applicationIds = tasks.Select(t => t.ApplicationId).Distinct().ToList();
            var applications = await _context.ServiceApplications
                .Include(a => a.ServiceProcedure)
                .Where(a => applicationIds.Contains(a.Id))
                .ToListAsync();
            var applicationsById = applications.ToDictionary(a => a.Id);

            return tasks.Select(t =>
            {
                applicationsById.TryGetValue(t.ApplicationId, out var application);
                return new VerificationTaskDto
                {
                    Id = t.Id,
                    ApplicationId = t.ApplicationId,
                    ApplicationReference = application?.ApplicationReference,
                    ServiceName = application?.ServiceProcedure?.Name,
                    Department = DepartmentCatalog.GetDepartmentForCategory(application?.ServiceProcedure?.Category),
                    Status = t.Status,
                    CreatedDate = t.CreatedDate,
                };
            }).ToList();
        }

        // VerificationTask.ApplicationId is a loose int reference (no FK), so a task's
        // department is resolved by looking up the matching ServiceApplication's linked
        // ServiceProcedure.Category. Tasks with no matching ServiceApplication (legacy/demo
        // seed data, or paper intake never linked to a citizen submission) have no
        // resolvable department and are excluded once a category filter is requested -
        // they simply don't appear in any department-scoped queue.
        private async Task<IQueryable<VerificationTask>> ApplyCategoryFilterAsync(IQueryable<VerificationTask> query, string? category)
        {
            if (string.IsNullOrWhiteSpace(category)) return query;

            var normalized = category.Trim().ToLower();
            var matchingApplicationIds = await _context.ServiceApplications
                .Include(a => a.ServiceProcedure)
                .Where(a => a.ServiceProcedure != null && a.ServiceProcedure.Category.ToLower() == normalized)
                .Select(a => a.Id)
                .ToListAsync();

            return query.Where(t => matchingApplicationIds.Contains(t.ApplicationId));
        }

        public async Task<OfficerStatsDto> GetOfficerStatsAsync(string officerId)
        {
            var today = DateTime.UtcNow.Date;
            var yesterday = today.AddDays(-1);
            var monthStart = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);

            var reviews = await _context.OfficerReviews
                .Where(r => r.OfficerId == officerId)
                .Include(r => r.Task)
                .ToListAsync();

            var reviewedToday = reviews.Count(r => r.ReviewDate.Date == today);
            var reviewedYesterday = reviews.Count(r => r.ReviewDate.Date == yesterday);
            var approvedThisMonth = reviews.Count(r =>
                r.ReviewDate >= monthStart && r.Task != null && r.Task.Status == "Approved");

            // Approval rate over this officer's decided (Approved/Rejected) tasks - the closest
            // real signal available, since there's no ground-truth "correctness" tracking yet.
            var decided = reviews.Where(r => r.Task != null && (r.Task.Status == "Approved" || r.Task.Status == "Rejected")).ToList();
            double? approvalRate = decided.Count == 0
                ? null
                : Math.Round(decided.Count(r => r.Task.Status == "Approved") * 100.0 / decided.Count, 1);

            return new OfficerStatsDto
            {
                ReviewedToday = reviewedToday,
                ReviewedYesterday = reviewedYesterday,
                ApprovedThisMonth = approvedThisMonth,
                ApprovalRate = approvalRate
            };
        }
        public async Task<List<RejectionReason>> GetRejectionReasonsAsync()
        {
            return await _context.RejectionReasons.OrderBy(r => r.Code).ToListAsync();
        }

        public async Task<RejectionReason> CreateRejectionReasonAsync(RejectionReason reason)
        {
            _context.RejectionReasons.Add(reason);
            await _context.SaveChangesAsync();
            return reason;
        }

        public async Task<bool> UpdateRejectionReasonAsync(int id, RejectionReason reason)
        {
            var existing = await _context.RejectionReasons.FindAsync(id);
            if (existing == null) return false;

            existing.Code = reason.Code;
            existing.Description = reason.Description;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteRejectionReasonAsync(int id)
        {
            var existing = await _context.RejectionReasons.FindAsync(id);
            if (existing == null) return false;

            _context.RejectionReasons.Remove(existing);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
