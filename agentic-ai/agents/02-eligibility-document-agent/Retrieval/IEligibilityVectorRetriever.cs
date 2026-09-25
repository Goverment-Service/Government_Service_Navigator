using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Pgvector;

namespace Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.Retrieval;

public interface IEligibilityVectorRetriever
{
    Task<List<string>> GetRelevantEligibilityContextAsync(
        Vector queryEmbedding, 
        string? categoryFilter = null, 
        int limit = 5, 
        CancellationToken cancellationToken = default);
}
