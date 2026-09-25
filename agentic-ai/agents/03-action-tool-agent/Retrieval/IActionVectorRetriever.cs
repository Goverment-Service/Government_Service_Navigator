using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Pgvector;

namespace Government_Service_Navigator.AgenticAi.Agents.ActionToolAgent.Retrieval;

public static class ActionKnowledgeCategories
{
    // All Agent 3 chunks in the vector DB share this SourceCategory prefix
    public const string Prefix = "ActionTool:";
    public const string Fees = Prefix + "Fees";
    public const string FormTemplate = Prefix + "FormTemplate";
    public const string AppointmentPolicy = Prefix + "AppointmentPolicy";
}

public interface IActionVectorRetriever
{
    /// <summary>Nearest-neighbour search restricted to ActionTool:* knowledge chunks.</summary>
    Task<List<string>> GetRelevantActionContextAsync(
        Vector queryEmbedding,
        int limit = 5,
        CancellationToken cancellationToken = default);
}
