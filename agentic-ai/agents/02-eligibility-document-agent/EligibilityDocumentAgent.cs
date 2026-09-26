using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AgenticAi.Agents.IntakePlanningAgent;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.DTOs;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.Retrieval;
using Government_Service_Navigator.AgenticAi.Tools.CheckEligibilityRules;
using Government_Service_Navigator.AgenticAi.Tools.GetDocumentRequirements;
using Pgvector;

namespace Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent;

/// <summary>
/// Agent 2 — evaluates eligibility with the allow-listed rules tool and takes the service's
/// required documents from the vector DB catalog chunk. No external LLM is called.
/// </summary>
public class EligibilityDocumentAgent : IEligibilityDocumentAgent
{
    private readonly IEligibilityVectorRetriever _retriever;
    private readonly IEmbeddingService _embeddingService;
    private readonly ICheckEligibilityRulesTool _rulesTool;
    private readonly IGetDocumentRequirementsTool _docsTool;

    public EligibilityDocumentAgent(
        IEligibilityVectorRetriever retriever, 
        IEmbeddingService embeddingService,
        ICheckEligibilityRulesTool rulesTool,
        IGetDocumentRequirementsTool docsTool)
    {
        _retriever = retriever;
        _embeddingService = embeddingService;
        _rulesTool = rulesTool;
        _docsTool = docsTool;
    }

    public async Task<EligibilityPlanResponse> EvaluateEligibilityAsync(
        EligibilityPlanRequest request, 
        CancellationToken cancellationToken = default)
    {
        var profile = request.Profile ?? new CitizenProfile();
        var providedDocs = profile.ProvidedDocuments ?? new List<string>();
        int serviceId = request.ServiceId ?? 1;

        // 1. Retrieve the service's catalog chunk from the vector DB
        var topContexts = new List<string>();
        ServiceCatalogChunk? serviceChunk = null;
        try
        {
            var queryText = $"{request.ServiceName}. {request.PlanSummary}";
            Vector queryEmbedding = await _embeddingService.GetEmbeddingAsync(queryText);

            topContexts = await _retriever.GetRelevantEligibilityContextAsync(
                queryEmbedding, 
                categoryFilter: null, 
                limit: 5, 
                cancellationToken: cancellationToken);

            serviceChunk = FindServiceChunk(topContexts, request.ServiceName);
        }
        catch
        {
            // Vector DB unavailable — the document requirements tool below reads the catalog directly
            topContexts = new List<string> { "Vector DB unavailable; document requirements tool fallback applied." };
        }

        // 2. Rules tool: age / citizenship criteria
        var ruleResult = _rulesTool.EvaluateRules(serviceId, profile.Age, profile.CitizenshipStatus);

        // 3. Required documents: when a specific stage is evaluated, use the stage-aware get_document_requirements tool.
        // Otherwise, prefer the vector DB catalog chunk with tool fallback.
        var fromVectorDb = serviceChunk != null && !request.Stage.HasValue;
        var requiredDocs = (request.Stage.HasValue || !fromVectorDb)
            ? await _docsTool.GetRequiredDocumentsForServiceAsync(serviceId, request.Stage, cancellationToken)
            : serviceChunk!.RequiredDocuments;

        var missingDocs = requiredDocs.Where(req => !providedDocs.Any(prov => DocumentMatches(req, prov))).ToList();

        // Eligibility is decided by the criteria only. Uploaded files are named freely by citizens, so documents
        // that cannot be matched by name are flagged for the Verifying Officer instead of blocking the draft.
        var isEligible = ruleResult.IsEligible;
        var reasoning = BuildReasoning(request.ServiceName, profile, ruleResult, requiredDocs, missingDocs, fromVectorDb, isEligible);

        return new EligibilityPlanResponse(
            IsEligible: isEligible,
            MatchPercentage: Math.Clamp(ruleResult.ScorePercentage - (missingDocs.Count * 15), 0, 100),
            MissingCriteria: ruleResult.MissingCriteria,
            RequiredDocuments: requiredDocs,
            MissingDocuments: missingDocs,
            Reasoning: reasoning,
            RetrievedContextSnippets: topContexts
        );
    }

    // Words that appear in upload labels / file names or in many document names and so prove nothing
    private static readonly HashSet<string> GenericDocumentWords = new(StringComparer.Ordinal)
    {
        "required", "upload", "uploaded", "attachment", "file", "copy", "scan", "pdf", "jpg", "jpeg", "png", "doc", "docx",
        "certificate", "card", "proof", "form", "completed", "official", "original", "letter"
    };

    /// <summary>
    /// A provided document satisfies a requirement when they share a distinctive keyword (e.g. "passport", "birth"),
    /// or the upload uses the requirement's initials (e.g. "nic" for National Identity Card).
    /// </summary>
    private static bool DocumentMatches(string required, string provided)
    {
        if (string.IsNullOrWhiteSpace(provided)) return false;

        var allRequiredTokens = TextTokenizer.Tokenize(required);
        var requiredTokens = allRequiredTokens.Where(t => !GenericDocumentWords.Contains(t)).ToList();
        var providedTokens = TextTokenizer.Tokenize(provided).Where(t => !GenericDocumentWords.Contains(t)).ToList();

        var initials = string.Concat(allRequiredTokens.Select(t => t[0]));
        if (initials.Length >= 2 && providedTokens.Contains(initials)) return true;

        return TextTokenizer.SharesKeyword(requiredTokens, providedTokens);
    }

    private static ServiceCatalogChunk? FindServiceChunk(List<string> contexts, string serviceName)
    {
        var chunks = contexts.Select(ServiceCatalogChunk.TryParse).Where(c => c != null).Select(c => c!).ToList();

        return chunks.FirstOrDefault(c => c.ServiceName.Equals(serviceName?.Trim(), StringComparison.OrdinalIgnoreCase))
            ?? chunks.FirstOrDefault(c => TextTokenizer.SharesKeyword(TextTokenizer.Tokenize(serviceName), c.KeywordTokens()));
    }

    private static string BuildReasoning(
        string serviceName,
        CitizenProfile profile,
        EligibilityRuleResult ruleResult,
        List<string> requiredDocs,
        List<string> missingDocs,
        bool fromVectorDb,
        bool isEligible)
    {
        var criteria = ruleResult.MissingCriteria.Count == 0
            ? $"The applicant meets the age ({profile.Age}) and citizenship ({profile.CitizenshipStatus}) criteria"
            : $"Criteria not met: {string.Join(" ", ruleResult.MissingCriteria)}";

        var source = fromVectorDb ? "the service catalog (vector DB)" : "the service catalog";
        var documents = requiredDocs.Count == 0
            ? $"{source} lists no required documents"
            : missingDocs.Count == 0
                ? $"all {requiredDocs.Count} documents required by {source} match an uploaded file"
                : $"not matched to an upload, officer to confirm (per {source}): {string.Join(", ", missingDocs)}";

        return $"{(isEligible ? "Eligible" : "Not yet eligible")} for {serviceName}. {criteria}; {documents}.";
    }
}
