using Microsoft.EntityFrameworkCore;
using Government_Service_Navigator.Backend.Models.Entities;

namespace Government_Service_Navigator.Backend.Data.Context
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Officer> Officers { get; set; }
        public DbSet<Admin> Admins { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<RefundRequest> RefundRequests { get; set; }
        public DbSet<InstallmentPlan> InstallmentPlans { get; set; }
        public DbSet<InstallmentScheduleItem> InstallmentScheduleItems { get; set; }
        public DbSet<ReportSnapshot> ReportSnapshots { get; set; }
        public DbSet<ServiceUsageStat> ServiceUsageStats { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Email).IsUnique();
            });
            modelBuilder.Entity<Officer>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Email).IsUnique();
            });
            modelBuilder.Entity<Admin>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Email).IsUnique();
            });

            // --- Member D: Payments, Refunds & Financial Analytics ---

            modelBuilder.Entity<Payment>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.ApplicationId);
                entity.Property(e => e.Amount).HasColumnType("decimal(12,2)");
                entity.Property(e => e.Status).HasConversion<string>();
            });

            modelBuilder.Entity<RefundRequest>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.PaymentId);
                entity.Property(e => e.Status).HasConversion<string>();
            });

            modelBuilder.Entity<InstallmentPlan>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.PaymentId);
                entity.Property(e => e.TotalAmount).HasColumnType("decimal(12,2)");
            });

            modelBuilder.Entity<InstallmentScheduleItem>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.InstallmentPlanId);
                entity.Property(e => e.AmountDue).HasColumnType("decimal(12,2)");
                entity.Property(e => e.AmountPaid).HasColumnType("decimal(12,2)");
                entity.Property(e => e.Status).HasConversion<string>();
            });

            modelBuilder.Entity<ReportSnapshot>(entity =>
            {
                entity.HasKey(e => e.Id);
            });

            modelBuilder.Entity<ServiceUsageStat>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => new { e.ServiceId, e.Date });
            });
        }
    }
}
