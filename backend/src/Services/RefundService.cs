using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services
{
    public class RefundService : IRefundService
    {
        private readonly AppDbContext _context;

        public RefundService(AppDbContext context)
        {
            _context = context;
        }

        // Methods implemented in upcoming commits.
        public Task<RefundRequest> CreateRefundRequestAsync(int paymentId, decimal amount, string reason, string requestedByEmail)
        {
            throw new NotImplementedException();
        }

        public Task<RefundRequest?> GetRefundByIdAsync(int id)
        {
            throw new NotImplementedException();
        }

        public Task<RefundRequest> ApproveAsync(int id, string decidedByEmail, string? note)
        {
            throw new NotImplementedException();
        }

        public Task<RefundRequest> RejectAsync(int id, string decidedByEmail, string? note)
        {
            throw new NotImplementedException();
        }

        public Task<RefundRequest> ProcessAsync(int id, string transactionRef)
        {
            throw new NotImplementedException();
        }

        public Task<RefundRequest> CompleteAsync(int id)
        {
            throw new NotImplementedException();
        }
    }
}