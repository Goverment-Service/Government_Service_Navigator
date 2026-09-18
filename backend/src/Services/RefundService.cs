using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services
{
    public class RefundService : IRefundService
    {
        private readonly AppDbContext _context;
        private readonly INotificationService _notificationService;

        public RefundService(AppDbContext context, INotificationService notificationService)
        {
            _context = context;
            _notificationService = notificationService;
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

                        await _notificationService.NotifyRefundStatusAsync(requestedByEmail, refund.Id, "Pending", null);

            _context.AuditLogs.Add(new AuditLog
            {
                ApplicationId = payment.ApplicationId,
                Action = "RefundRequestCreated",
                PerformedBy = requestedByEmail,
                Timestamp = DateTime.UtcNow,
                OldValues = "",
                NewValues = $"RefundId={refund.Id}, Amount={refund.RefundAmount}, Status=Pending"
            });
            await _context.SaveChangesAsync();

            return refund;
        }


        public async Task<List<RefundRequest>> GetAllAsync(string? status)
        {
            var query = _context.RefundRequests
                .Include(r => r.Payment)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(status) &&
                Enum.TryParse<RefundStatus>(status, ignoreCase: true, out var parsedStatus))
            {
                query = query.Where(r => r.Status == parsedStatus);
            }

            return await query
                .OrderByDescending(r => r.RequestedDate)
                .ToListAsync();
        }

        public async Task<RefundRequest?> GetRefundByIdAsync(int id)
        {
            return await _context.RefundRequests
                .Include(r => r.Payment)
                .FirstOrDefaultAsync(r => r.Id == id);
        }

        public async Task<RefundRequest> ApproveAsync(int id, string decidedByEmail, string? note)
        {
            var refund = await _context.RefundRequests.FindAsync(id);

            if (refund == null)
            {
                throw new KeyNotFoundException($"Refund request {id} not found.");
            }

            if (refund.Status != RefundStatus.Pending)
            {
                throw new InvalidOperationException("Only pending refund requests can be approved.");
            }

            refund.Status = RefundStatus.Approved;
            refund.DecidedByEmail = decidedByEmail;
            refund.DecisionNote = note;
            refund.DecidedDate = DateTime.UtcNow;

            await _context.SaveChangesAsync();

                        await _notificationService.NotifyRefundStatusAsync(refund.RequestedByEmail, refund.Id, "Approved", note);

            _context.AuditLogs.Add(new AuditLog
            {
                ApplicationId = 0,
                Action = "RefundApproved",
                PerformedBy = decidedByEmail,
                Timestamp = DateTime.UtcNow,
                OldValues = "Status=Pending",
                NewValues = $"RefundId={refund.Id}, Status=Approved, Note={note}"
            });
            await _context.SaveChangesAsync();

            return refund;
        }


        public async Task<RefundRequest> RejectAsync(int id, string decidedByEmail, string? note)
        {
            var refund = await _context.RefundRequests.FindAsync(id);

            if (refund == null)
            {
                throw new KeyNotFoundException($"Refund request {id} not found.");
            }

            if (refund.Status != RefundStatus.Pending)
            {
                throw new InvalidOperationException("Only pending refund requests can be rejected.");
            }

            refund.Status = RefundStatus.Rejected;
            refund.DecidedByEmail = decidedByEmail;
            refund.DecisionNote = note;
            refund.DecidedDate = DateTime.UtcNow;

            await _context.SaveChangesAsync();

                        await _notificationService.NotifyRefundStatusAsync(refund.RequestedByEmail, refund.Id, "Rejected", note);

            _context.AuditLogs.Add(new AuditLog
            {
                ApplicationId = 0,
                Action = "RefundRejected",
                PerformedBy = decidedByEmail,
                Timestamp = DateTime.UtcNow,
                OldValues = "Status=Pending",
                NewValues = $"RefundId={refund.Id}, Status=Rejected, Note={note}"
            });
            await _context.SaveChangesAsync();

            return refund;
        }

        public async Task<RefundRequest> ProcessAsync(int id, string transactionRef)
        {
            var refund = await _context.RefundRequests.FindAsync(id);

            if (refund == null)
            {
                throw new KeyNotFoundException($"Refund request {id} not found.");
            }

            if (refund.Status != RefundStatus.Approved)
            {
                throw new InvalidOperationException("Only approved refund requests can be processed.");
            }

            if (string.IsNullOrWhiteSpace(transactionRef))
            {
                throw new ArgumentException("A transaction reference is required to process a refund.");
            }

            refund.Status = RefundStatus.Processing;
            refund.RefundTransactionRef = transactionRef;

            await _context.SaveChangesAsync();

            return refund;
        }

        public async Task<RefundRequest> CompleteAsync(int id)
        {
            var refund = await _context.RefundRequests
                .Include(r => r.Payment)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (refund == null)
            {
                throw new KeyNotFoundException($"Refund request {id} not found.");
            }

            if (refund.Status != RefundStatus.Processing)
            {
                throw new InvalidOperationException("Only processing refund requests can be completed.");
            }

            refund.Status = RefundStatus.Completed;
            refund.CompletedDate = DateTime.UtcNow;

            // Reflect the refund on the original payment.
            if (refund.Payment != null)
            {
                refund.Payment.Status = "Refunded";
            }

            await _context.SaveChangesAsync();

                        await _notificationService.NotifyRefundStatusAsync(refund.RequestedByEmail, refund.Id, "Completed", null);

            _context.AuditLogs.Add(new AuditLog
            {
                ApplicationId = refund.Payment?.ApplicationId ?? 0,
                Action = "RefundCompleted",
                PerformedBy = "system",
                Timestamp = DateTime.UtcNow,
                OldValues = "Status=Processing",
                NewValues = $"RefundId={refund.Id}, Status=Completed"
            });
            await _context.SaveChangesAsync();

            return refund;
        }
    }
}