using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly AppDbContext _context;

        public PaymentService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<Payment> CreateManualPaymentAsync(int applicationId, decimal amount, string userEmail, string slipUrl)
        {
            var payment = new Payment
            {
                ApplicationId = applicationId,
                Amount = amount,
                Currency = "LKR",
                Method = "Manual",
                Status = "PendingVerification",
                ManualSlipUrl = slipUrl,
                UserEmail = userEmail,
                CreatedDate = DateTime.UtcNow
            };

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            return payment;
        }

        public async Task<Payment?> GetByIdAsync(int id)
        {
            return await _context.Payments
                .Include(p => p.RefundRequests)
                .FirstOrDefaultAsync(p => p.Id == id);
        }

        public async Task<Payment> VerifyManualPaymentAsync(int id, bool approved, string? note)
        {
            var payment = await _context.Payments.FindAsync(id);

            if (payment == null)
            {
                throw new KeyNotFoundException($"Payment {id} not found.");
            }

            if (payment.Status != "PendingVerification")
            {
                throw new InvalidOperationException("Only payments pending verification can be reviewed.");
            }

            if (approved)
            {
                payment.Status = "Paid";
                payment.PaidDate = DateTime.UtcNow;
            }
            else
            {
                payment.Status = "Failed";
            }

            await _context.SaveChangesAsync();

            return payment;
        }

        public async Task<PaymentLedgerDto> GetLedgerAsync(int id)
        {
            var payment = await _context.Payments
                .Include(p => p.RefundRequests)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (payment == null)
            {
                throw new KeyNotFoundException($"Payment {id} not found.");
            }

            var entries = new List<LedgerEntryDto>
            {
                new LedgerEntryDto
                {
                    Type = "Payment",
                    Amount = payment.Amount,
                    Date = payment.PaidDate ?? payment.CreatedDate,
                    Description = $"Payment via {payment.Method}"
                }
            };

            decimal totalRefunded = 0;

            if (payment.RefundRequests != null)
            {
                foreach (var refund in payment.RefundRequests.Where(r => r.Status == RefundStatus.Completed))
                {
                    entries.Add(new LedgerEntryDto
                    {
                        Type = "Refund",
                        Amount = -refund.RefundAmount,
                        Date = refund.CompletedDate ?? refund.RequestedDate,
                        Description = $"Refund: {refund.Reason}"
                    });

                    totalRefunded += refund.RefundAmount;
                }
            }

            return new PaymentLedgerDto
            {
                PaymentId = payment.Id,
                OriginalAmount = payment.Amount,
                TotalRefunded = totalRefunded,
                RunningBalance = payment.Amount - totalRefunded,
                Status = payment.Status,
                Entries = entries.OrderBy(e => e.Date).ToList()
            };
        }
    }
}