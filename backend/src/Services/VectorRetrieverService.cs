using AgenticAi.Agents.IntakePlanningAgent;
using Backend.Data;
using Microsoft.EntityFrameworkCore;
using Pgvector;
using Pgvector.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services;

public class VectorRetrieverService : IVectorRetriever
{
    private readonly VectorDbContext _vectorDb;

    public VectorRetrieverService(VectorDbContext vectorDb)
    {
        _vectorDb = vectorDb;
    }

    public async Task<List<string>> GetRelevantContextAsync(Vector queryEmbedding, int limit, CancellationToken cancellationToken = default)
    {
        // EF Core handles the actual DB interaction here
        return await _vectorDb.KnowledgeChunks
            .OrderBy(c => c.Embedding.CosineDistance(queryEmbedding))
            .Take(limit)
            .Select(c => c.Content)
            .ToListAsync(cancellationToken);
    }
}
