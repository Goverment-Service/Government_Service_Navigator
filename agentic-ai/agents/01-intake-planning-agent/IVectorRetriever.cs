using Pgvector;

namespace AgenticAi.Agents.IntakePlanningAgent;

public interface IVectorRetriever
{
    Task<List<string>> GetRelevantContextAsync(Vector queryEmbedding, int limit, CancellationToken cancellationToken = default);
}
