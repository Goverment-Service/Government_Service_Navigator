using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services
{
    /// <summary>
    /// Hourly check of active installment plans:
    /// - reminds the citizen once when an unpaid installment is due within <see cref="ReminderWindow"/>;
    /// - when an installment passes its due date unpaid, cancels the plan and the application it pays for.
    /// A bank transfer awaiting verification ("PendingVerification") is not treated as unpaid.
    /// </summary>
    public class InstallmentMonitorService : BackgroundService
    {
        private static readonly TimeSpan CheckInterval = TimeSpan.FromHours(1);
        private static readonly TimeSpan ReminderWindow = TimeSpan.FromDays(3);

        // Task statuses that are already final and must not be overwritten by a cancellation
        private static readonly string[] FinalTaskStatuses = { "Approved", "Rejected", "Cancelled" };

        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<InstallmentMonitorService> _logger;

        public InstallmentMonitorService(IServiceScopeFactory scopeFactory, ILogger<InstallmentMonitorService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // Let startup (table creation in Program.cs) finish first
            await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);

            using var timer = new PeriodicTimer(CheckInterval);
            do
            {
                try
                {
                    await CheckPlansAsync(stoppingToken);
                }
                catch (Exception ex) when (ex is not OperationCanceledException)
                {
                    _logger.LogError(ex, "Installment monitor run failed");
                }
            }
            while (await timer.WaitForNextTickAsync(stoppingToken));
        }

        public async Task CheckPlansAsync(CancellationToken cancellationToken)
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var email = scope.ServiceProvider.GetRequiredService<INotificationService>();
            var now = DateTime.UtcNow;

            var plans = await db.InstallmentPlans
                .Include(p => p.Installments)
                .Include(p => p.Payment)
                .Where(p => p.Status == "Active")
                .ToListAsync(cancellationToken);

            foreach (var plan in plans)
            {
                var payment = plan.Payment;
                if (payment == null || plan.Installments == null) continue;

                var submission = await db.ApplicationSubmissions
                    .Include(s => s.ServiceProcedure)
                    .FirstOrDefaultAsync(s => s.Id == payment.ApplicationId, cancellationToken);
                var reference = $"APP-{payment.ApplicationId}";
                var serviceName = submission?.ServiceProcedure?.Name ?? "your application";

                var missed = plan.Installments
                    .Where(i => (i.Status == "Pending" || i.Status == "Overdue") && i.DueDate < now)
                    .OrderBy(i => i.InstallmentNumber)
                    .FirstOrDefault();

                if (missed != null)
                {
                    plan.Status = "Cancelled";

                    var tasks = await db.VerificationTasks
                        .Where(t => t.ApplicationId == payment.ApplicationId && !FinalTaskStatuses.Contains(t.Status))
                        .ToListAsync(cancellationToken);
                    foreach (var task in tasks) task.Status = "Cancelled";

                    await NotifyAsync(db, email, submission, payment, plan, "ApplicationCancelled",
                        $"{reference} cancelled",
                        $"Installment #{missed.InstallmentNumber} (LKR {missed.Amount:N2}) for {serviceName} was not paid by " +
                        $"its due date {missed.DueDate:yyyy-MM-dd}, so the installment plan and application {reference} have been cancelled.");

                    _logger.LogInformation("Cancelled installment plan {PlanId} and application {ApplicationId}: installment {Number} missed",
                        plan.Id, payment.ApplicationId, missed.InstallmentNumber);
                    continue;
                }

                foreach (var due in plan.Installments.Where(i =>
                             i.Status == "Pending" && i.ReminderSentAt == null && i.DueDate <= now + ReminderWindow))
                {
                    due.ReminderSentAt = now;
                    await NotifyAsync(db, email, submission, payment, plan, "InstallmentReminder",
                        $"Installment #{due.InstallmentNumber} due {due.DueDate:MMM d}",
                        $"Installment #{due.InstallmentNumber} of LKR {due.Amount:N2} for {serviceName} ({reference}) is due on " +
                        $"{due.DueDate:yyyy-MM-dd}. If it is not paid by then, the application will be cancelled automatically.");
                }
            }

            await db.SaveChangesAsync(cancellationToken);
        }

        private async Task NotifyAsync(
            AppDbContext db,
            INotificationService email,
            ApplicationSubmission? submission,
            Payment payment,
            InstallmentPlan plan,
            string type,
            string title,
            string message)
        {
            var toEmail = !string.IsNullOrWhiteSpace(payment.UserEmail) ? payment.UserEmail : submission?.UserEmail ?? string.Empty;

            db.CitizenNotifications.Add(new CitizenNotification
            {
                CitizenNic = submission?.CitizenNic ?? string.Empty,
                UserEmail = toEmail,
                Type = type,
                Title = title,
                Message = message,
                ApplicationId = payment.ApplicationId,
                InstallmentPlanId = plan.Id,
                CreatedAt = DateTime.UtcNow
            });

            if (string.IsNullOrWhiteSpace(toEmail)) return;
            try
            {
                await email.SendEmailAsync(toEmail, title, message);
            }
            catch (Exception ex)
            {
                // The in-app notification is still stored; email is best effort
                _logger.LogWarning(ex, "Could not email installment notification to {Email}", toEmail);
            }
        }
    }
}
