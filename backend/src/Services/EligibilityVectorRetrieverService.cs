using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Backend.Data;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.Retrieval;
using Microsoft.EntityFrameworkCore;
using Pgvector;
using Pgvector.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services;

public class EligibilityVectorRetrieverService : IEligibilityVectorRetriever
{
    private readonly VectorDbContext _vectorDb;

    public EligibilityVectorRetrieverService(VectorDbContext vectorDb)
    {
        _vectorDb = vectorDb;
    }

    public async Task<List<string>> GetRelevantEligibilityContextAsync(
        Vector queryEmbedding, 
        string? categoryFilter = null, 
        int limit = 5, 
        CancellationToken cancellationToken = default)
    {
        IQueryable<KnowledgeChunk> query = _vectorDb.KnowledgeChunks;

        if (!string.IsNullOrWhiteSpace(categoryFilter))
        {
            query = query.Where(c => c.SourceCategory.ToLower() == categoryFilter.ToLower());
        }

        return await query
            .OrderBy(c => c.Embedding.CosineDistance(queryEmbedding))
            .Take(limit)
            .Select(c => c.Content)
            .ToListAsync(cancellationToken);
    }
}
