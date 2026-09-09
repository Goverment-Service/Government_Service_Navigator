using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Requests;
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
            // TODO: Implement logic
            throw new NotImplementedException();
        }

        public async Task<bool> RecordDecisionAsync(int taskId, VerificationDecisionRequest request, string officerId)
        {
            // TODO: Implement logic with Database Transaction
            throw new NotImplementedException();
        }

        public async Task<bool> DeleteTaskAsync(int taskId, string officerId)
        {
            // TODO: Implement logic
            throw new NotImplementedException();
        }

        public async Task<bool> BulkVerifyAsync(BulkVerifyRequest request, string officerId)
        {
            // TODO: Implement logic with Database Transaction
            throw new NotImplementedException();
        }

        public async Task<List<AuditLog>> GetAuditLogsAsync(int applicationId)
        {
            return await _context.AuditLogs
                .Where(a => a.ApplicationId == applicationId)
                .OrderByDescending(a => a.Timestamp)
                .ToListAsync();
        }
    }
}
