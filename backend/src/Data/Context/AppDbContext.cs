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
        public DbSet<VerificationTask> VerificationTasks {get; set;}
        public DbSet<OfficerReview> OfficerReviews {get; set;}
        public DbSet<ComplianceCheck> ComplianceChecks {get; set;}
        public DbSet<RejectionReason> RejectionReasons {get; set;}
        public DbSet<AuditLog> AuditLogs {get; set;}
        public DbSet<Template> Templates { get; set; }
        public DbSet<FormField> FormFields { get; set; }
        public DbSet<ServiceProcedure> ServiceProcedures { get; set; }
        public DbSet<EligibilityRule> EligibilityRules { get; set; }
        public DbSet<DocumentRequirement> DocumentRequirements { get; set; }
        public DbSet<FeeSchedule> FeeSchedules { get; set; }
        public DbSet<RevokedToken> RevokedTokens { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<PaymentRefund> PaymentRefunds { get; set; }
        public DbSet<ServiceApplication> ServiceApplications { get; set; }
        public DbSet<ApplicationDocument> ApplicationDocuments { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<ServiceProcedure>()
                .HasIndex(s => s.ServiceId)
                .IsUnique();
            
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
            // Relationships for Verification and Compliance
            modelBuilder.Entity<OfficerReview>(entity =>
            {
                entity.HasOne(r => r.Task)
                      .WithMany(t => t.Reviews)
                      .HasForeignKey(r => r.TaskId);
            });
            
            modelBuilder.Entity<ComplianceCheck>(entity =>
            {
                entity.HasOne(c => c.Task)
                      .WithMany(t => t.ComplianceChecks)
                      .HasForeignKey(c => c.TaskId);
            });

            modelBuilder.Entity<RevokedToken>()
                .HasIndex(t => t.Jti)
                .IsUnique();

            modelBuilder.Entity<Payment>(entity =>
            {
                entity.HasIndex(p => p.TransactionReference).IsUnique();
                entity.HasOne(p => p.User)
                      .WithMany()
                      .HasForeignKey(p => p.UserId)
                      .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<PaymentRefund>(entity =>
            {
                entity.HasIndex(r => r.RequestToken).IsUnique();
                entity.HasOne(r => r.Payment)
                      .WithOne(p => p.Refund)
                      .HasForeignKey<PaymentRefund>(r => r.PaymentId)
                      .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<ServiceApplication>(entity =>
            {
                entity.HasIndex(a => a.ApplicationReference).IsUnique();
                entity.HasOne(a => a.User)
                      .WithMany()
                      .HasForeignKey(a => a.UserId)
                      .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(a => a.ServiceProcedure)
                      .WithMany()
                      .HasForeignKey(a => a.ServiceProcedureId)
                      .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<ApplicationDocument>(entity =>
            {
                entity.HasOne(d => d.ServiceApplication)
                      .WithMany()
                      .HasForeignKey(d => d.ServiceApplicationId)
                      .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Template>()
                .HasMany(t => t.Fields)
                .WithOne(f => f.Template)
                .HasForeignKey(f => f.TemplateId)
                .OnDelete(DeleteBehavior.Cascade);

            // Optional link - deleting a Service Catalog entry unlinks its templates
            // rather than deleting them.
            modelBuilder.Entity<Template>()
                .HasOne(t => t.ServiceProcedure)
                .WithMany()
                .HasForeignKey(t => t.ServiceProcedureId)
                .OnDelete(DeleteBehavior.SetNull);
        }
    }
}
