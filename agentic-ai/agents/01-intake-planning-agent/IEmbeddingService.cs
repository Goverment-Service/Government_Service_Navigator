using Pgvector;
using System.Threading.Tasks;

namespace AgenticAi.Agents.IntakePlanningAgent;

/// <summary>
/// Turns text into a 768-dimension vector for pgvector similarity search.
/// Knowledge chunks and queries must be embedded by the same implementation.
/// </summary>
public interface IEmbeddingService
{
    Task<Vector> GetEmbeddingAsync(string text);
}
