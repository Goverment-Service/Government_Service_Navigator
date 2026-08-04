using GSN.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GSN.Infrastructure.Persistence {
    public class GsnDbContext : DbContext {
        public GsnDbContext(DbContextOptions<GsnDbContext> options) : base(options) {}

        public DbSet<User> Users => Set<User>();

        protected override void OnModelCreating(ModelBuilder modelBuilder) {
            base.OnModelCreating(modelBuilder);
            modelBuilder.Entity<User>(entity => {
                entity.HasKey(u => u.Id);
                entity.HasIndex(u => u.Email).IsUnique();
                entity.Property(u => u.Email).IsRequired();
                entity.Property(u => u.FullName).IsRequired();
                entity.Property(u => u.PasswordHash).IsRequired();
                entity.Property(u => u.Role).HasConversion<string>();
            });
        }
    }
}
