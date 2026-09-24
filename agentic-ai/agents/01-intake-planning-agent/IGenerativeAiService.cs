using Pgvector;
using System.Threading.Tasks;

namespace AgenticAi.Agents.IntakePlanningAgent;

public interface IGenerativeAiService
{
    Task<Vector> GetEmbeddingAsync(string text);
    Task<string> GenerateTextAsync(string prompt);
}
