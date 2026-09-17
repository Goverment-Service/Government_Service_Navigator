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

        public async Task<InstallmentPlanResponseDto?> GetByIdAsync(int id)
        {
            var plan = await _context.InstallmentPlans
                .Include(p => p.Installments)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (plan == null) return null;

            // Flag any pending installments that are now past due.
            var today = DateTime.UtcNow;
            var changed = false;

            if (plan.Installments != null)
            {
                foreach (var installment in plan.Installments)
                {
                    if (installment.Status == "Pending" && installment.DueDate < today)
                    {
                        installment.Status = "Overdue";
                        changed = true;
                    }
                }
            }

            if (changed)
            {
                await _context.SaveChangesAsync();
            }

            return InstallmentPlanResponseDto.FromEntity(plan);
        }

        public async Task<Installment> MarkInstallmentPaidAsync(int installmentId)
        {
            var installment = await _context.Installments
                .Include(i => i.InstallmentPlan)
                .FirstOrDefaultAsync(i => i.Id == installmentId);

            if (installment == null)
            {
                throw new KeyNotFoundException($"Installment {installmentId} not found.");
            }

            if (installment.Status == "Paid")
            {
                throw new InvalidOperationException("This installment is already marked as paid.");
            }

            installment.Status = "Paid";
            installment.PaidDate = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // If every installment in the plan is now paid, mark the plan itself Completed.
            var plan = installment.InstallmentPlan;
            if (plan != null)
            {
                var allInstallments = await _context.Installments
                    .Where(i => i.InstallmentPlanId == plan.Id)
                    .ToListAsync();

                if (allInstallments.All(i => i.Status == "Paid"))
                {
                    plan.Status = "Completed";
                    await _context.SaveChangesAsync();
                }
            }

            return installment;
        }
    }
}