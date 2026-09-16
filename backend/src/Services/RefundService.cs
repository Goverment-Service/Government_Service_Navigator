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

                        var hasActiveRefund = await _context.RefundRequests.AnyAsync(r =>
                r.PaymentId == paymentId &&
                (r.Status == RefundStatus.Pending || r.Status == RefundStatus.Approved || r.Status == RefundStatus.Processing));

            if (hasActiveRefund)
            {
                throw new InvalidOperationException("An active refund request already exists for this payment.");
            }
        
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

        public async Task<RefundRequest?> GetRefundByIdAsync(int id)
        {
            return await _context.RefundRequests
                .Include(r => r.Payment)
                .FirstOrDefaultAsync(r => r.Id == id);
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