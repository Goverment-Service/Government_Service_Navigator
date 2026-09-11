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

            modelBuilder.Entity<Template>()
                .HasMany(t => t.Fields)
                .WithOne(f => f.Template)
                .HasForeignKey(f => f.TemplateId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
