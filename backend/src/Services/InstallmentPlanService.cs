using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services
{
    public class InstallmentPlanService : IInstallmentPlanService
    {
        private readonly AppDbContext _context;

        public InstallmentPlanService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<InstallmentPlan> CreatePlanAsync(int paymentId, int numberOfInstallments, int intervalDays)
        {
            var payment = await _context.Payments.FindAsync(paymentId);

            if (payment == null)
            {
                throw new KeyNotFoundException($"Payment {paymentId} not found.");
            }

            if (numberOfInstallments < 2)
            {
                throw new ArgumentException("An installment plan needs at least 2 installments.");
            }

            var hasActivePlan = await _context.InstallmentPlans.AnyAsync(p =>
                p.PaymentId == paymentId && p.Status == "Active");

            if (hasActivePlan)
            {
                throw new InvalidOperationException("This payment already has an active installment plan.");
            }

            // Split the total amount evenly; put any rounding remainder on the last installment.
            var baseAmount = Math.Floor((payment.Amount / numberOfInstallments) * 100) / 100;
            var remainder = payment.Amount - (baseAmount * numberOfInstallments);

            var plan = new InstallmentPlan
            {
                PaymentId = paymentId,
                NumberOfInstallments = numberOfInstallments,
                TotalAmount = payment.Amount,
                Status = "Active",
                Installments = new List<Installment>()
            };

            for (int i = 1; i <= numberOfInstallments; i++)
            {
                var amount = (i == numberOfInstallments) ? baseAmount + remainder : baseAmount;

                plan.Installments.Add(new Installment
                {
                    InstallmentNumber = i,
                    Amount = amount,
                    DueDate = DateTime.UtcNow.AddDays(intervalDays * i),
                    Status = "Pending"
                });
            }

            _context.InstallmentPlans.Add(plan);
            await _context.SaveChangesAsync();

            return plan;
        }

        public Task<InstallmentPlanResponseDto?> GetByIdAsync(int id)
        {
            // Implemented in the next commit.
            throw new NotImplementedException();
        }

        public Task<Installment> MarkInstallmentPaidAsync(int installmentId)
        {
            // Implemented in the next commit.
            throw new NotImplementedException();
        }
    }
}