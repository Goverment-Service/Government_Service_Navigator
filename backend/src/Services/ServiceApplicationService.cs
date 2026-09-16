using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Services
{
    public class ServiceApplicationService : IServiceApplicationService
    {
        private readonly AppDbContext _context;

        public ServiceApplicationService(AppDbContext context)
        {
            _context = context;
        }

        private static string GenerateReference() =>
            $"APP-{DateTime.UtcNow:yyyy}-{Guid.NewGuid().ToString("N")[..6].ToUpperInvariant()}";

        public async Task<ApplicationDto> SubmitApplicationAsync(int userId, SubmitApplicationRequest request)
        {
            var service = await _context.ServiceProcedures.FindAsync(request.ServiceProcedureId)
                ?? throw new InvalidOperationException("Service not found.");
            if (service.Status != "Active")
                throw new InvalidOperationException("This service is not currently accepting applications.");

            using var transaction = await _context.Database.BeginTransactionAsync();

            var application = new ServiceApplication
            {
                ApplicationReference = GenerateReference(),
                UserId = userId,
                ServiceProcedureId = request.ServiceProcedureId,
                AnswersJson = JsonSerializer.Serialize(request.Answers ?? new Dictionary<string, string>()),
                SubmittedAt = DateTime.UtcNow,
            };
            _context.ServiceApplications.Add(application);
            await _context.SaveChangesAsync();

            // Drop straight into the existing Officer review queue - the same
            // VerificationTask/PendingReviews workflow Officers already use.
            _context.VerificationTasks.Add(new VerificationTask
            {
                ApplicationId = application.Id,
                Status = "Pending",
                CreatedDate = DateTime.UtcNow,
            });
            await _context.SaveChangesAsync();

            await transaction.CommitAsync();

            return await MapToDtoAsync(application, service);
        }

        public async Task<List<ApplicationDto>> GetMyApplicationsAsync(int userId)
        {
            var applications = await _context.ServiceApplications
                .Include(a => a.ServiceProcedure)
                .Where(a => a.UserId == userId)
                .OrderByDescending(a => a.SubmittedAt)
                .ToListAsync();

            var appIds = applications.Select(a => a.Id).ToList();
            var tasksByAppId = await LoadLatestTaskInfoAsync(appIds);

            return applications.Select(a => MapToDto(a, a.ServiceProcedure, tasksByAppId.GetValueOrDefault(a.Id))).ToList();
        }

        public async Task<ApplicationDto?> GetApplicationForUserAsync(int applicationId, int userId)
        {
            var application = await _context.ServiceApplications
                .Include(a => a.ServiceProcedure)
                .FirstOrDefaultAsync(a => a.Id == applicationId && a.UserId == userId);
            if (application == null) return null;

            var tasksByAppId = await LoadLatestTaskInfoAsync(new List<int> { application.Id });
            return MapToDto(application, application.ServiceProcedure, tasksByAppId.GetValueOrDefault(application.Id));
        }

        private record TaskInfo(string Status, DateTime? DecisionAt, string? DecisionNotes);

        private async Task<Dictionary<int, TaskInfo>> LoadLatestTaskInfoAsync(List<int> applicationIds)
        {
            if (applicationIds.Count == 0) return new Dictionary<int, TaskInfo>();

            var tasks = await _context.VerificationTasks
                .Where(t => applicationIds.Contains(t.ApplicationId))
                .OrderByDescending(t => t.CreatedDate)
                .ToListAsync();

            var taskIds = tasks.Select(t => t.Id).ToList();
            var latestReviews = await _context.OfficerReviews
                .Where(r => taskIds.Contains(r.TaskId))
                .OrderByDescending(r => r.ReviewDate)
                .ToListAsync();

            var result = new Dictionary<int, TaskInfo>();
            foreach (var group in tasks.GroupBy(t => t.ApplicationId))
            {
                var latestTask = group.First();
                var review = latestReviews.FirstOrDefault(r => r.TaskId == latestTask.Id);
                result[group.Key] = new TaskInfo(latestTask.Status, review?.ReviewDate, review?.Comments);
            }
            return result;
        }

        private async Task<ApplicationDto> MapToDtoAsync(ServiceApplication application, ServiceProcedure service)
        {
            var tasksByAppId = await LoadLatestTaskInfoAsync(new List<int> { application.Id });
            return MapToDto(application, service, tasksByAppId.GetValueOrDefault(application.Id));
        }

        private static ApplicationDto MapToDto(ServiceApplication application, ServiceProcedure? service, TaskInfo? taskInfo)
        {
            Dictionary<string, string> answers;
            try
            {
                answers = JsonSerializer.Deserialize<Dictionary<string, string>>(application.AnswersJson) ?? new();
            }
            catch
            {
                answers = new();
            }

            return new ApplicationDto
            {
                Id = application.Id,
                ApplicationReference = application.ApplicationReference,
                ServiceProcedureId = application.ServiceProcedureId,
                ServiceName = service?.Name ?? string.Empty,
                Category = service?.Category ?? string.Empty,
                Department = DepartmentCatalog.GetDepartmentForCategory(service?.Category),
                Status = taskInfo?.Status ?? "Pending",
                SubmittedAt = application.SubmittedAt,
                DecisionAt = taskInfo?.DecisionAt,
                DecisionNotes = taskInfo?.DecisionNotes,
                Answers = answers,
            };
        }
    }
}
