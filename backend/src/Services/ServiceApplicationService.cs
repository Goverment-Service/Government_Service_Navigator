using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
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
        private const long MaxDocumentSizeBytes = 10 * 1024 * 1024; // 10 MB
        private static readonly string[] AllowedDocumentExtensions = { ".jpg", ".jpeg", ".png", ".pdf" };

        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _environment;

        public ServiceApplicationService(AppDbContext context, IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }

        private static string GenerateReference() =>
            $"APP-{DateTime.UtcNow:yyyy}-{Guid.NewGuid().ToString("N")[..6].ToUpperInvariant()}";

        private string DocumentDirectory
        {
            get
            {
                var dir = Path.Combine(_environment.ContentRootPath, "App_Data", "application-documents");
                Directory.CreateDirectory(dir);
                return dir;
            }
        }

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

        public async Task<ApplicationDocumentDto> UploadDocumentAsync(int applicationId, int userId, int? documentRequirementId, string documentName, IFormFile file)
        {
            var application = await _context.ServiceApplications
                .FirstOrDefaultAsync(a => a.Id == applicationId && a.UserId == userId)
                ?? throw new InvalidOperationException("Application not found.");

            if (file == null || file.Length == 0)
                throw new InvalidOperationException("A document file is required.");
            if (file.Length > MaxDocumentSizeBytes)
                throw new InvalidOperationException("The document must be smaller than 10 MB.");

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!AllowedDocumentExtensions.Contains(extension))
                throw new InvalidOperationException("Only JPG, PNG, or PDF documents are accepted.");

            var storedFileName = $"{Guid.NewGuid():N}{extension}";
            var fullPath = Path.Combine(DocumentDirectory, storedFileName);
            await using (var stream = new FileStream(fullPath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var document = new ApplicationDocument
            {
                ServiceApplicationId = application.Id,
                DocumentRequirementId = documentRequirementId,
                DocumentName = documentName,
                FilePath = storedFileName,
                FileName = file.FileName,
                UploadedAt = DateTime.UtcNow,
            };
            _context.ApplicationDocuments.Add(document);
            await _context.SaveChangesAsync();

            return MapDocumentToDto(document);
        }

        public async Task<List<ApplicationDocumentDto>> GetDocumentsForUserAsync(int applicationId, int userId)
        {
            var owned = await _context.ServiceApplications.AnyAsync(a => a.Id == applicationId && a.UserId == userId);
            if (!owned) return new List<ApplicationDocumentDto>();

            var documents = await _context.ApplicationDocuments
                .Where(d => d.ServiceApplicationId == applicationId)
                .OrderBy(d => d.UploadedAt)
                .ToListAsync();
            return documents.Select(MapDocumentToDto).ToList();
        }

        public async Task<SlipFileResult?> GetDocumentFileForUserAsync(int applicationId, int documentId, int userId)
        {
            var owned = await _context.ServiceApplications.AnyAsync(a => a.Id == applicationId && a.UserId == userId);
            if (!owned) return null;

            var document = await _context.ApplicationDocuments
                .FirstOrDefaultAsync(d => d.Id == documentId && d.ServiceApplicationId == applicationId);
            if (document == null) return null;

            var fullPath = Path.Combine(DocumentDirectory, document.FilePath);
            if (!File.Exists(fullPath)) return null;

            var extension = Path.GetExtension(fullPath).ToLowerInvariant();
            var contentType = extension switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".pdf" => "application/pdf",
                _ => "application/octet-stream",
            };

            return new SlipFileResult
            {
                Bytes = await File.ReadAllBytesAsync(fullPath),
                ContentType = contentType,
                FileName = document.FileName,
            };
        }

        private static ApplicationDocumentDto MapDocumentToDto(ApplicationDocument document) => new()
        {
            Id = document.Id,
            ServiceApplicationId = document.ServiceApplicationId,
            DocumentRequirementId = document.DocumentRequirementId,
            DocumentName = document.DocumentName,
            FileName = document.FileName,
            UploadedAt = document.UploadedAt,
        };

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
