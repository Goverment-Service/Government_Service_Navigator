using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using AgenticAi.Agents.IntakePlanningAgent;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.DTOs;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.Retrieval;
using Government_Service_Navigator.AgenticAi.Tools.CheckEligibilityRules;
using Government_Service_Navigator.AgenticAi.Tools.GetDocumentRequirements;
using Pgvector;

namespace Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent;

public class EligibilityDocumentAgent : IEligibilityDocumentAgent
{
    private readonly IEligibilityVectorRetriever _retriever;
    private readonly IGenerativeAiService _aiService;
    private readonly ICheckEligibilityRulesTool _rulesTool;
    private readonly IGetDocumentRequirementsTool _docsTool;

    public EligibilityDocumentAgent(
        IEligibilityVectorRetriever retriever, 
        IGenerativeAiService aiService,
        ICheckEligibilityRulesTool rulesTool,
        IGetDocumentRequirementsTool docsTool)
    {
        _retriever = retriever;
        _aiService = aiService;
        _rulesTool = rulesTool;
        _docsTool = docsTool;
    }

    public async Task<EligibilityPlanResponse> EvaluateEligibilityAsync(
        EligibilityPlanRequest request, 
        CancellationToken cancellationToken = default)
    {
        var profile = request.Profile ?? new CitizenProfile();
        var providedDocsStr = profile.ProvidedDocuments != null && profile.ProvidedDocuments.Count > 0
            ? string.Join(", ", profile.ProvidedDocuments)
            : "None";

        try
        {
            // 1. Build composite query string for embedding search
            var queryText = $"Service: {request.ServiceName}. Age: {profile.Age}, Citizenship: {profile.CitizenshipStatus}, Income: {profile.AnnualIncome}, Employment: {profile.EmploymentStatus}, Documents: {providedDocsStr}. {request.PlanSummary}";

            // 2. Vectorize user & service profile query
            Vector queryEmbedding = await _aiService.GetEmbeddingAsync(queryText);

            // 3. Retrieve relevant knowledge chunks from vector DB
            var topContexts = await _retriever.GetRelevantEligibilityContextAsync(
                queryEmbedding, 
                categoryFilter: null, 
                limit: 5, 
                cancellationToken: cancellationToken);

            var retrievedContext = string.Join("\n\n---\n\n", topContexts);

            // 4. Construct prompt for Gemini API with strict structured JSON contract
            var systemPrompt = $$"""
                You are the Eligibility & Document Analysis Agent (Agent 2) for the Government Service Navigator system.
                Your task is to analyze a citizen's profile and plan against official government service requirements and rules.

                Determine:
                1. Is the citizen eligible? (isEligible: true/false)
                2. Match percentage (matchPercentage: 0-100 integer score)
                3. List of missing or failed eligibility criteria (missingCriteria: string array)
                4. Required documents for this service (requiredDocuments: string array)
                5. Missing documents that the citizen has NOT yet provided (missingDocuments: string array)
                6. Detailed AI reasoning explaining the evaluation result (reasoning: string)

                CRITICAL RULE: Respond ONLY in valid raw JSON with NO markdown wrappers (do NOT use ```json or ```).

                Expected JSON schema:
                {
                  "isEligible": true,
                  "matchPercentage": 85,
                  "missingCriteria": ["Age requirement must be 18+"],
                  "requiredDocuments": ["National ID Card", "Proof of Residence", "Income Certificate"],
                  "missingDocuments": ["Proof of Residence"],
                  "reasoning": "The citizen satisfies age and citizenship criteria, but is missing proof of residence."
                }

                [OFFICIAL GOVERNMENT SERVICE RULES & DOCUMENT REQUIREMENTS CONTEXT]
                {{retrievedContext}}

                [TARGET SERVICE NAME]
                {{request.ServiceName}}

                [CITIZEN PROFILE & PROVIDED DOCUMENTS]
                Age: {{profile.Age}}
                Citizenship Status: {{profile.CitizenshipStatus}}
                Annual Income: LKR {{profile.AnnualIncome}}
                Employment Status: {{profile.EmploymentStatus}}
                Provided Documents: {{providedDocsStr}}
                Plan / Additional Details: {{request.PlanSummary ?? "None"}}
                """;

            // 5. Generate structured response from Gemini
            var rawResponse = await _aiService.GenerateTextAsync(systemPrompt);

            // Clean any markdown formatting tags
            var cleanedJson = rawResponse
                .Replace("```json", "", StringComparison.OrdinalIgnoreCase)
                .Replace("```", "")
                .Trim();

            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var parsed = JsonSerializer.Deserialize<AgentStructuredOutput>(cleanedJson, options);

            return new EligibilityPlanResponse(
                IsEligible: parsed?.IsEligible ?? true,
                MatchPercentage: parsed?.MatchPercentage ?? 100,
                MissingCriteria: parsed?.MissingCriteria ?? new List<string>(),
                RequiredDocuments: parsed?.RequiredDocuments ?? new List<string>(),
                MissingDocuments: parsed?.MissingDocuments ?? new List<string>(),
                Reasoning: parsed?.Reasoning ?? cleanedJson,
                RetrievedContextSnippets: topContexts
            );
        }
        catch
        {
            // Deterministic Fallback using allow-listed tools if AI service / API key fails
            int serviceId = request.ServiceId ?? 1;
            var ruleResult = _rulesTool.EvaluateRules(serviceId, profile.Age, profile.CitizenshipStatus);
            var requiredDocs = _docsTool.GetRequiredDocumentsForService(serviceId);

            var providedSet = new HashSet<string>(profile.ProvidedDocuments.Select(d => d.ToLower().Trim()));
            var missingDocs = requiredDocs
                .Where(req => !providedSet.Any(prov => prov.Contains(req.ToLower()) || req.ToLower().Contains(prov)))
                .ToList();

            var fallbackReasoning = $"Evaluated using rules engine. Applicant meets basic age ({profile.Age}) and citizenship ({profile.CitizenshipStatus}) criteria for {request.ServiceName}.";

            return new EligibilityPlanResponse(
                IsEligible: ruleResult.IsEligible && missingDocs.Count == 0,
                MatchPercentage: Math.Max(50, ruleResult.ScorePercentage - (missingDocs.Count * 15)),
                MissingCriteria: ruleResult.MissingCriteria,
                RequiredDocuments: requiredDocs,
                MissingDocuments: missingDocs,
                Reasoning: fallbackReasoning,
                RetrievedContextSnippets: new List<string> { "Rule evaluation fallback applied." }
            );
        }
    }

    private class AgentStructuredOutput
    {
        public bool IsEligible { get; set; } = true;
        public int MatchPercentage { get; set; } = 100;
        public List<string>? MissingCriteria { get; set; }
        public List<string>? RequiredDocuments { get; set; }
        public List<string>? MissingDocuments { get; set; }
        public string? Reasoning { get; set; }
    }
}
