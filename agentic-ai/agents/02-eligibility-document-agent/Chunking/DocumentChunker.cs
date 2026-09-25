using System;
using System.Collections.Generic;
using System.Text;

namespace Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.Chunking;

public class DocumentChunker : IDocumentChunker
{
    public List<string> ChunkText(string text, int maxChunkSize = 500, int overlap = 50)
    {
        if (string.IsNullOrWhiteSpace(text))
            return new List<string>();

        text = text.Trim();
        if (text.Length <= maxChunkSize)
            return new List<string> { text };

        var chunks = new List<string>();
        // Split text into paragraphs or sentences first for cleaner boundaries
        var paragraphs = text.Split(new[] { "\r\n\r\n", "\n\n" }, StringSplitOptions.RemoveEmptyEntries);

        var currentChunk = new StringBuilder();

        foreach (var paragraph in paragraphs)
        {
            var p = paragraph.Trim();
            if (p.Length == 0) continue;

            if (currentChunk.Length + p.Length + 2 <= maxChunkSize)
            {
                if (currentChunk.Length > 0)
                    currentChunk.Append("\n\n");
                currentChunk.Append(p);
            }
            else
            {
                // Current paragraph doesn't fit, store current chunk if not empty
                if (currentChunk.Length > 0)
                {
                    chunks.Add(currentChunk.ToString());
                    currentChunk.Clear();
                }

                // If the single paragraph exceeds maxChunkSize, split by sentence or word
                if (p.Length > maxChunkSize)
                {
                    var sentenceChunks = ChunkLongTextByWords(p, maxChunkSize, overlap);
                    chunks.AddRange(sentenceChunks);
                }
                else
                {
                    currentChunk.Append(p);
                }
            }
        }

        if (currentChunk.Length > 0)
        {
            chunks.Add(currentChunk.ToString());
        }

        return chunks;
    }

    public List<TextChunk> ChunkDocument(
        string title, 
        string content, 
        string sourceCategory, 
        int maxChunkSize = 500, 
        int overlap = 50)
    {
        var textChunks = ChunkText(content, maxChunkSize, overlap);
        var result = new List<TextChunk>();

        for (int i = 0; i < textChunks.Count; i++)
        {
            result.Add(new TextChunk(
                Content: textChunks[i],
                ChunkIndex: i,
                SourceTitle: title,
                SourceCategory: sourceCategory
            ));
        }

        return result;
    }

    private static List<string> ChunkLongTextByWords(string text, int maxChunkSize, int overlap)
    {
        var words = text.Split(new[] { ' ', '\t', '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
        var result = new List<string>();
        var currentChunk = new StringBuilder();
        int currentWordIndex = 0;

        while (currentWordIndex < words.Length)
        {
            currentChunk.Clear();
            int startIndex = currentWordIndex;

            while (currentWordIndex < words.Length)
            {
                string word = words[currentWordIndex];
                if (currentChunk.Length + word.Length + 1 > maxChunkSize && currentChunk.Length > 0)
                {
                    break;
                }

                if (currentChunk.Length > 0)
                    currentChunk.Append(' ');
                currentChunk.Append(word);
                currentWordIndex++;
            }

            if (currentChunk.Length > 0)
            {
                result.Add(currentChunk.ToString());
            }

            // Step back for overlap if possible
            if (overlap > 0 && currentWordIndex < words.Length && currentWordIndex > startIndex + 1)
            {
                int stepBackWords = Math.Max(1, overlap / 10);
                currentWordIndex = Math.Max(startIndex + 1, currentWordIndex - stepBackWords);
            }
        }

        return result;
    }
}
