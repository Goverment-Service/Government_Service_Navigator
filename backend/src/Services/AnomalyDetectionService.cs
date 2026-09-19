using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services
{
    public class AnomalyDetectionService : IAnomalyDetectionService
    {
        private readonly AppDbContext _context;

        // Simple rule-based thresholds; can be tuned or replaced with a smarter model later.
        private const decimal HighAmountThreshold = 100000m;
        private const int RapidRefundWindowMinutes = 10;

        public AnomalyDetectionService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<List<AnomalyFlag>> ScanAsync()
        {
            var newFlags = new List<AnomalyFlag>();

            // Rule 1: unusually large payments.
            var largePayments = await _context.Payments
                .Where(p => p.Amount >= HighAmountThreshold && p.Status == "Paid")
                .ToListAsync();

            foreach (var payment in largePayments)
            {
                var alreadyFlagged = await _context.AnomalyFlags.AnyAsync(a =>
                    a.PaymentId == payment.Id && a.AnomalyType == "HighAmount");

                if (!alreadyFlagged)
                {
                    newFlags.Add(new AnomalyFlag
                    {
                        PaymentId = payment.Id,
                        AnomalyType = "HighAmount",
                        Description = $"Payment of {payment.Amount} {payment.Currency} exceeds the normal threshold.",
                        Status = "Open"
                    });
                }
            }

            // Rule 2: refund requested suspiciously soon after payment.
            var recentPayments = await _context.Payments
                .Include(p => p.RefundRequests)
                .Where(p => p.PaidDate != null && p.RefundRequests != null && p.RefundRequests.Any())
                .ToListAsync();

            foreach (var payment in recentPayments)
            {
                var earliestRefund = payment.RefundRequests!.OrderBy(r => r.RequestedDate).First();

                if ((earliestRefund.RequestedDate - payment.PaidDate!.Value).TotalMinutes <= RapidRefundWindowMinutes)
                {
                    var alreadyFlagged = await _context.AnomalyFlags.AnyAsync(a =>
                        a.PaymentId == payment.Id && a.AnomalyType == "RapidRefund");

                    if (!alreadyFlagged)
                    {
                        newFlags.Add(new AnomalyFlag
                        {
                            PaymentId = payment.Id,
                            AnomalyType = "RapidRefund",
                            Description = $"Refund requested within {RapidRefundWindowMinutes} minutes of payment.",
                            Status = "Open"
                        });
                    }
                }
            }

            if (newFlags.Any())
            {
                _context.AnomalyFlags.AddRange(newFlags);
                await _context.SaveChangesAsync();
            }

            return newFlags;
        }

        public async Task<List<AnomalyFlag>> GetOpenFlagsAsync()
        {
            return await _context.AnomalyFlags
                .Where(a => a.Status == "Open")
                .OrderByDescending(a => a.DetectedDate)
                .ToListAsync();
        }

        public async Task<AnomalyFlag> ResolveFlagAsync(int id, string status, string reviewedByEmail)
        {
            var flag = await _context.AnomalyFlags.FindAsync(id);

            if (flag == null)
            {
                throw new KeyNotFoundException($"Anomaly flag {id} not found.");
            }

            flag.Status = status;
            flag.ReviewedByEmail = reviewedByEmail;
            flag.ReviewedDate = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return flag;
        }
    }
}