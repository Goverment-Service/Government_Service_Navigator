using Backend.Data;
using Government_Service_Navigator.AgenticAi.Agents.ActionToolAgent.Retrieval;
using Microsoft.EntityFrameworkCore;
using Pgvector;
using Pgvector.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services;

public class ActionVectorRetrieverService : IActionVectorRetriever
{
    private readonly VectorDbContext _vectorDb;

    public ActionVectorRetrieverService(VectorDbContext vectorDb)
    {
        _vectorDb = vectorDb;
    }

    public async Task<List<string>> GetRelevantActionContextAsync(
        Vector queryEmbedding,
        int limit = 5,
        CancellationToken cancellationToken = default)
    {
        return await _vectorDb.KnowledgeChunks
            .Where(c => c.SourceCategory.StartsWith(ActionKnowledgeCategories.Prefix))
            .OrderBy(c => c.Embedding.CosineDistance(queryEmbedding))
            .Take(limit)
            .Select(c => c.Content)
            .ToListAsync(cancellationToken);
    }
}
