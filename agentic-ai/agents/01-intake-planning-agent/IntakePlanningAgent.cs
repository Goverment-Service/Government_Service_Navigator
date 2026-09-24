using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Pgvector;

namespace AgenticAi.Agents.IntakePlanningAgent;

public class IntakePlanningAgent : IIntakePlanningAgent
{
    private readonly IVectorRetriever _retriever;
    private readonly IGenerativeAiService _aiService;

    public IntakePlanningAgent(IVectorRetriever retriever, IGenerativeAiService aiService)
    {
        _retriever = retriever;
        _aiService = aiService;
    }

    public async Task<IntakePlanResponse> GeneratePlanAsync(
        IntakePlanRequest request, 
        CancellationToken cancellationToken = default)
    {
        // 1. Vectorize user query
        Vector queryEmbedding = await _aiService.GetEmbeddingAsync(request.UserNeedDescription);

        // 2. Retrieve top matching knowledge chunks
        var topResults = await _retriever.GetRelevantContextAsync(queryEmbedding, 3, cancellationToken);
        var retrievedContext = string.Join("\n\n---\n\n", topResults);
        // 3. System prompt instructing strict JSON output and fallback logic
        var systemPrompt = $$"""
            You are a Government Service Intake Assistant.
            Using ONLY the provided documentation, analyze the citizen's need.
            
            CRITICAL RULE: Vector search may return loosely related documents. You must evaluate if the [OFFICIAL DOCUMENTATION] actually answers the [USER REQUEST]. 
            If the documentation does NOT match the request (e.g., they ask for Passports, but documentation is only about Vehicles or Land), you MUST reject it.

            Respond strictly in valid raw JSON with NO markdown wrappers (do not use ```json).

            If the documentation MATCHES the request:
            {
              "recommendedService": "Name of the government procedure",
              "requiredDocuments": ["Document 1", "Document 2"],
              "stepByStepPlan": [
                "Step 1: Description",
                "Step 2: Description"
              ]
            }

            If the documentation DOES NOT MATCH the request:
            {
              "recommendedService": "Service Not Found",
              "requiredDocuments": [],
              "stepByStepPlan": [
                "We currently do not offer services matching your request in our system. Please contact the main helpdesk."
              ]
            }

            [OFFICIAL DOCUMENTATION]
            {{retrievedContext}}

            [USER REQUEST]
            {{request.UserNeedDescription}}
            """;


        // 4. Generate structured response
        var rawResponse = await _aiService.GenerateTextAsync(systemPrompt);

        // Sanitize any potential markdown tags returned by the model
        var cleanedJson = rawResponse
            .Replace("```json", "", StringComparison.OrdinalIgnoreCase)
            .Replace("```", "")
            .Trim();

        try
        {
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var parsed = JsonSerializer.Deserialize<AgentStructuredOutput>(cleanedJson, options);

            return new IntakePlanResponse(
                RecommendedService: parsed?.RecommendedService ?? "General Procedure",
                RequiredDocuments: parsed?.RequiredDocuments ?? new List<string>(),
                StepByStepPlan: parsed?.StepByStepPlan ?? new List<string> { rawResponse },
                RetrievedContextSnippets: topResults
            );
        }
        catch
        {
            // Fallback if parsing fails
            return new IntakePlanResponse(
                RecommendedService: "Government Service Request",
                RequiredDocuments: new List<string>(),
                StepByStepPlan: new List<string> { rawResponse },
                RetrievedContextSnippets: topResults
            );
        }
    }

    private class AgentStructuredOutput
    {
        public string? RecommendedService { get; set; }
        public List<string>? RequiredDocuments { get; set; }
        public List<string>? StepByStepPlan { get; set; }
    }
}
