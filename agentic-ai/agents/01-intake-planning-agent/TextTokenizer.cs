using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace AgenticAi.Agents.IntakePlanningAgent;

/// <summary>
/// Normalizes free text into comparable keyword tokens (lower-case, stop words removed, light stemming).
/// Shared by the local embedding service and the agents' relevance checks so both agree on what a "word" is.
/// </summary>
public static class TextTokenizer
{
    private static readonly Regex WordPattern = new(@"[a-z0-9]+", RegexOptions.Compiled);

    private static readonly HashSet<string> StopWords = new(StringComparer.Ordinal)
    {
        "a", "an", "and", "are", "as", "at", "be", "by", "can", "do", "for", "from", "get", "have", "how",
        "i", "in", "is", "it", "me", "my", "need", "of", "on", "or", "please", "service", "services", "so",
        "the", "this", "to", "want", "what", "with", "would", "you", "your", "apply", "application",
        "citizen", "citizens", "must", "provide", "following", "applicable", "fee", "fees", "document", "documents"
    };

    public static List<string> Tokenize(string? text)
    {
        if (string.IsNullOrWhiteSpace(text)) return new List<string>();

        return WordPattern.Matches(text.ToLowerInvariant())
            .Select(m => Stem(m.Value))
            .Where(t => t.Length >= 2 && !StopWords.Contains(t))
            .ToList();
    }

    /// <summary>True when the two token sets share a word, or one word is a prefix (4+ chars) of the other, e.g. renew / renewal.</summary>
    public static bool SharesKeyword(IEnumerable<string> left, IEnumerable<string> right)
    {
        var rightList = right.ToList();
        return left.Any(l => rightList.Any(r =>
            l == r || (Math.Min(l.Length, r.Length) >= 4 && (l.StartsWith(r, StringComparison.Ordinal) || r.StartsWith(l, StringComparison.Ordinal)))));
    }

    private static string Stem(string word)
    {
        if (word.Length > 4 && word.EndsWith("ies", StringComparison.Ordinal)) return word[..^3] + "y";
        if (word.Length > 3 && word.EndsWith('s') && !word.EndsWith("ss", StringComparison.Ordinal)) return word[..^1];
        return word;
    }
}
