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

            if (payment.PaidDate == null || (DateTime.UtcNow - payment.PaidDate.Value).TotalDays > 3)
            {
                throw new InvalidOperationException("Refund window has expired. Refunds are only allowed within 3 days of payment.");
            }

            // Duplicate-refund check added in the next commit.

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