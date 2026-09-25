using System.Collections.Generic;

namespace Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.Chunking;

public record TextChunk(
    string Content,
    int ChunkIndex,
    string SourceTitle,
    string SourceCategory
);

public interface IDocumentChunker
{
    List<string> ChunkText(string text, int maxChunkSize = 500, int overlap = 50);
    List<TextChunk> ChunkDocument(string title, string content, string sourceCategory, int maxChunkSize = 500, int overlap = 50);
}
