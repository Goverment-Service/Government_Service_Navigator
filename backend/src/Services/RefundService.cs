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
        public async Task<RefundRequest> CreateRefundRequestAsync(int paymentId, decimal amount, string reason, string requestedByEmail)
        {
            var payment = await _context.Payments.FindAsync(paymentId);

            if (payment == null)
            {
                throw new KeyNotFoundException($"Payment {paymentId} not found.");
            }

            if (payment.Status != "Paid")
            {
                throw new InvalidOperationException("Only paid payments are eligible for a refund request.");
            }

            // Eligibility window and duplicate checks are added in the next commits.

            var refund = new RefundRequest
            {
                PaymentId = paymentId,
                RefundAmount = amount,
                Reason = reason,
                RequestedByEmail = requestedByEmail,
                Status = RefundStatus.Pending
            };

            _context.RefundRequests.Add(refund);
            await _context.SaveChangesAsync();

            return refund;
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