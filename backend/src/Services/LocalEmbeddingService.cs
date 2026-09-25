using System;
using System.Threading.Tasks;
using AgenticAi.Agents.IntakePlanningAgent;
using Pgvector;

namespace Government_Service_Navigator.Backend.Services;

/// <summary>
/// Offline embedding service: hashes keyword unigrams and bigrams into a 768-dimension vector
/// (the size of the KnowledgeChunks.Embedding column). No external API is called.
/// Cosine similarity between two vectors reflects their shared keywords, so re-seed the vector DB
/// (POST api/RagSetup/seed and seed-action-agent) whenever this algorithm changes.
/// </summary>
public class LocalEmbeddingService : IEmbeddingService
{
    public const int Dimensions = 768;

    public Task<Vector> GetEmbeddingAsync(string text)
    {
        var values = new float[Dimensions];
        var tokens = TextTokenizer.Tokenize(text);

        for (int i = 0; i < tokens.Count; i++)
        {
            Add(values, tokens[i], 1f);
            if (i + 1 < tokens.Count) Add(values, $"{tokens[i]} {tokens[i + 1]}", 0.5f);
        }

        double norm = 0;
        foreach (var v in values) norm += v * v;

        if (norm == 0)
        {
            // pgvector's cosine distance is undefined for a zero vector
            values[0] = 1f;
        }
        else
        {
            var scale = (float)(1 / Math.Sqrt(norm));
            for (int i = 0; i < values.Length; i++) values[i] *= scale;
        }

        return Task.FromResult(new Vector(values));
    }

    private static void Add(float[] values, string feature, float weight)
    {
        // FNV-1a: string.GetHashCode is randomized per process, which would break stored embeddings
        uint hash = 2166136261;
        foreach (var c in feature)
        {
            hash ^= c;
            hash *= 16777619;
        }

        var sign = (hash & 0x80000000) == 0 ? 1f : -1f;
        values[hash % Dimensions] += sign * weight;
    }
}
