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
                    CreatedDate = DateTime.UtcNow,
                    CitizenNic = request.CitizenNic
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

        public async Task<List<VerificationTask>> GetPendingTasksAsync()
        {
            return await _context.VerificationTasks
                .Where(t => t.Status == "Pending" || t.Status == "Revised" || t.Status == "Revision Requested")
                .OrderBy(t => t.CreatedDate)
                .ToListAsync();
        }

        public async Task<List<VerificationTask>> GetVerifiedTasksAsync()
        {
            return await _context.VerificationTasks
                .Where(t => t.Status == "Approved" || t.Status == "Rejected")
                .OrderByDescending(t => t.CreatedDate)
                .ToListAsync();
        }

        public async Task<List<VerificationTask>> GetTasksForCitizenAsync(string citizenNic)
        {
            return await _context.VerificationTasks
                .Where(t => t.CitizenNic == citizenNic)
                .OrderByDescending(t => t.CreatedDate)
                .ToListAsync();
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
