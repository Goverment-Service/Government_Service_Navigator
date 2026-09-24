using Microsoft.EntityFrameworkCore;
using Pgvector;
using Pgvector.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore.Design;


namespace Backend.Data;

public class KnowledgeChunk
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    
    public string Content { get; set; } = string.Empty;
    
    public string SourceCategory { get; set; } = string.Empty;

    // The dimension (768) must match the output size of your embedding model (e.g., OpenAI text-embedding-3-small)
    [Column(TypeName = "vector(768)")]
    public Vector Embedding { get; set; } = null!;
}

public class VectorDbContext : DbContext
{
    public VectorDbContext(DbContextOptions<VectorDbContext> options) : base(options) { }

    public DbSet<KnowledgeChunk> KnowledgeChunks => Set<KnowledgeChunk>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Activates the pgvector extension on the Neon PostgreSQL database
        modelBuilder.HasPostgresExtension("vector");

        // Creates an HNSW index for high-performance approximate nearest-neighbor search
        modelBuilder.Entity<KnowledgeChunk>()
            .HasIndex(c => c.Embedding)
            .HasMethod("hnsw")
            .HasOperators("vector_cosine_ops")
            .HasStorageParameter("m", 16)
            .HasStorageParameter("ef_construction", 64);
    }
    // EF Core CLI will automatically find this factory when you run 'dotnet ef' commands
public class VectorDbContextFactory : IDesignTimeDbContextFactory<VectorDbContext>
{
    public VectorDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<VectorDbContext>();
        
        // Hardcode the connection string here ONLY for design-time migration generation
        var connString = "Host=ep-misty-butterfly-b4qrxqf8-pooler.c-6.us-east-2.aws.neon.tech;Database=gsn_vectordb;Username=neondb_owner;Password=npg_tqMl8jnI7Fag;Ssl Mode=Require;Trust Server Certificate=true";
        
        optionsBuilder.UseNpgsql(connString, o => o.UseVector());

        return new VectorDbContext(optionsBuilder.Options);
    }
}

}
