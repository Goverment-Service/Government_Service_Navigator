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
            // Vector DB unavailable — fall back to the document requirements tool below
            topContexts = new List<string> { "Vector DB unavailable; document requirements tool fallback applied." };
        }

        // 2. Rules tool: age / citizenship criteria
        var ruleResult = _rulesTool.EvaluateRules(serviceId, profile.Age, profile.CitizenshipStatus);

        // 3. Required documents: catalog chunk first, generic requirements tool otherwise
        var fromCatalog = serviceChunk != null;
        var requiredDocs = fromCatalog ? serviceChunk!.RequiredDocuments : _docsTool.GetRequiredDocumentsForService(serviceId);

        var providedSet = providedDocs.Where(d => !string.IsNullOrWhiteSpace(d)).Select(d => d.ToLower().Trim()).ToList();
        var missingDocs = requiredDocs
            .Where(req => !providedSet.Any(prov => prov.Contains(req.ToLower()) || req.ToLower().Contains(prov)))
            .ToList();

        var isEligible = ruleResult.IsEligible && missingDocs.Count == 0;
        var reasoning = BuildReasoning(request.ServiceName, profile, ruleResult, requiredDocs, missingDocs, fromCatalog, isEligible);

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
        bool fromCatalog,
        bool isEligible)
    {
        var criteria = ruleResult.MissingCriteria.Count == 0
            ? $"The applicant meets the age ({profile.Age}) and citizenship ({profile.CitizenshipStatus}) criteria"
            : $"Criteria not met: {string.Join(" ", ruleResult.MissingCriteria)}";

        var source = fromCatalog ? "the service catalog" : "the standard document requirements";
        var documents = requiredDocs.Count == 0
            ? $"{source} lists no required documents"
            : missingDocs.Count == 0
                ? $"all {requiredDocs.Count} documents required by {source} were provided"
                : $"missing documents per {source}: {string.Join(", ", missingDocs)}";

        return $"{(isEligible ? "Eligible" : "Not yet eligible")} for {serviceName}. {criteria}; {documents}.";
    }
}
