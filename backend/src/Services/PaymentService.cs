using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly AppDbContext _context;

        public PaymentService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<RefundResponse> CreateRefundRequestAsync(int paymentId, CreateRefundRequestRequest request)
        {
            var payment = await _context.Payments.FirstOrDefaultAsync(p => p.Id == paymentId);

            if (payment == null)
            {
                return new RefundResponse { Success = false, ErrorMessage = "Payment not found." };
            }

            // Prevent duplicate open refund requests on the same payment
            var hasOpenRequest = await _context.RefundRequests.AnyAsync(r =>
                r.PaymentId == paymentId &&
                (r.Status == RefundStatus.Requested || r.Status == RefundStatus.UnderReview));

            if (hasOpenRequest)
            {
                return new RefundResponse { Success = false, ErrorMessage = "A refund request is already in progress for this payment." };
            }

            var refundRequest = new RefundRequest
            {
                PaymentId = paymentId,
                Reason = request.Reason,
                Status = RefundStatus.Requested,
                RequestedAt = DateTime.UtcNow
            };

            _context.RefundRequests.Add(refundRequest);
            await _context.SaveChangesAsync();

            return new RefundResponse
            {
                Success = true,
                RefundRequest = new RefundRequestDto
                {
                    Id = refundRequest.Id,
                    PaymentId = refundRequest.PaymentId,
                    Reason = refundRequest.Reason,
                    Status = refundRequest.Status.ToString(),
                    RequestedAt = refundRequest.RequestedAt,
                    ResolvedAt = refundRequest.ResolvedAt
                }
            };
        }

        public async Task<LedgerResponse> GetLedgerAsync(int paymentId)
        {
            var payment = await _context.Payments.FirstOrDefaultAsync(p => p.Id == paymentId);

            if (payment == null)
            {
                return new LedgerResponse { Success = false, ErrorMessage = "Payment not found." };
            }

            var ledger = new LedgerDto
            {
                PaymentId = payment.Id,
                ApplicationId = payment.ApplicationId,
                OriginalAmount = payment.Amount,
                Currency = payment.Currency,
                PaymentStatus = payment.Status.ToString()
            };

            // Original charge entry
            ledger.Entries.Add(new LedgerEntryDto
            {
                Type = "Payment",
                Description = $"Fee charged for application #{payment.ApplicationId}",
                Amount = payment.Amount,
                Date = payment.CreatedAt,
                Status = payment.Status.ToString()
            });

            // Installment payments, if any
            var installmentPlan = await _context.InstallmentPlans.FirstOrDefaultAsync(ip => ip.PaymentId == paymentId);
            if (installmentPlan != null)
            {
                var scheduleItems = await _context.InstallmentScheduleItems
                    .Where(si => si.InstallmentPlanId == installmentPlan.Id)
                    .OrderBy(si => si.InstallmentNumber)
                    .ToListAsync();

                foreach (var item in scheduleItems.Where(si => si.AmountPaid > 0))
                {
                    ledger.Entries.Add(new LedgerEntryDto
                    {
                        Type = "Installment",
                        Description = $"Installment #{item.InstallmentNumber} payment",
                        Amount = item.AmountPaid,
                        Date = item.DueDate,
                        Status = item.Status.ToString()
                    });
                }
            }

            // Refund history
            var refunds = await _context.RefundRequests
                .Where(r => r.PaymentId == paymentId)
                .OrderBy(r => r.RequestedAt)
                .ToListAsync();

            decimal totalRefunded = 0;
            foreach (var refund in refunds)
            {
                if (refund.Status == RefundStatus.Refunded)
                {
                    totalRefunded += payment.Amount;
                    ledger.Entries.Add(new LedgerEntryDto
                    {
                        Type = "Refund",
                        Description = $"Refund issued: {refund.Reason}",
                        Amount = -payment.Amount,
                        Date = refund.ResolvedAt ?? refund.RequestedAt,
                        Status = refund.Status.ToString()
                    });
                }
                else
                {
                    ledger.Entries.Add(new LedgerEntryDto
                    {
                        Type = "Refund",
                        Description = $"Refund requested: {refund.Reason}",
                        Amount = 0,
                        Date = refund.RequestedAt,
                        Status = refund.Status.ToString()
                    });
                }
            }

            ledger.RunningBalance = payment.Amount - totalRefunded;
            ledger.Entries = ledger.Entries.OrderBy(e => e.Date).ToList();

            return new LedgerResponse { Success = true, Ledger = ledger };
        }
    }
}
