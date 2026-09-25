using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Pgvector;

namespace AgenticAi.Agents.IntakePlanningAgent;

/// <summary>
/// Agent 1 — matches the citizen's need to a service using the vector DB only.
/// The plan is built from the matched catalog chunk; no external LLM is called.
/// </summary>
public class IntakePlanningAgent : IIntakePlanningAgent
{
    private const string NotFound = "Service Not Found";

    private readonly IVectorRetriever _retriever;
    private readonly IEmbeddingService _embeddingService;

    public IntakePlanningAgent(IVectorRetriever retriever, IEmbeddingService embeddingService)
    {
        _retriever = retriever;
        _embeddingService = embeddingService;
    }

    public async Task<IntakePlanResponse> GeneratePlanAsync(
        IntakePlanRequest request, 
        CancellationToken cancellationToken = default)
    {
        // 1. Vectorize user query
        Vector queryEmbedding = await _embeddingService.GetEmbeddingAsync(request.UserNeedDescription);

        // 2. Retrieve top matching knowledge chunks (ordered by cosine distance)
        var topResults = await _retriever.GetRelevantContextAsync(queryEmbedding, 3, cancellationToken);

        // 3. Vector search always returns something, so only accept a chunk whose service name/category
        //    shares a keyword with the request (e.g. a passport request must not match Vehicle Registration)
        var queryTokens = TextTokenizer.Tokenize(request.UserNeedDescription);
        var match = topResults
            .Select(ServiceCatalogChunk.TryParse)
            .FirstOrDefault(chunk => chunk != null && TextTokenizer.SharesKeyword(queryTokens, chunk.KeywordTokens()));

        if (match == null)
        {
            return new IntakePlanResponse(
                RecommendedService: NotFound,
                RequiredDocuments: new List<string>(),
                StepByStepPlan: new List<string>
                {
                    "We currently do not offer services matching your request in our system. Please contact the main helpdesk."
                },
                RetrievedContextSnippets: topResults);
        }

        // 4. Build the plan from the matched catalog entry
        var steps = new List<string>();
        steps.Add(match.RequiredDocuments.Count > 0
            ? $"Step {steps.Count + 1}: Gather the required documents: {string.Join(", ", match.RequiredDocuments)}."
            : $"Step {steps.Count + 1}: No specific documents are required for this service.");
        steps.Add($"Step {steps.Count + 1}: Submit an application for {match.ServiceName} through the portal.");
        steps.Add($"Step {steps.Count + 1}: Pay the applicable fees: {match.FeeText}.");
        steps.Add($"Step {steps.Count + 1}: Track your application status until a Verifying Officer completes the review.");

        return new IntakePlanResponse(
            RecommendedService: match.ServiceName,
            RequiredDocuments: match.RequiredDocuments,
            StepByStepPlan: steps,
            RetrievedContextSnippets: topResults);
    }
}
