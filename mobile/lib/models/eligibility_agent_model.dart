class EligibilityAgentResponse {
  final bool isEligible;
  final int matchPercentage;
  final List<String> missingCriteria;
  final List<String> requiredDocuments;
  final List<String> missingDocuments;
  final String reasoning;
  final List<String> retrievedContextSnippets;

  EligibilityAgentResponse({
    required this.isEligible,
    required this.matchPercentage,
    required this.missingCriteria,
    required this.requiredDocuments,
    required this.missingDocuments,
    required this.reasoning,
    required this.retrievedContextSnippets,
  });

  factory EligibilityAgentResponse.fromJson(Map<String, dynamic> json) {
    return EligibilityAgentResponse(
      isEligible: json['isEligible'] ?? true,
      matchPercentage: json['matchPercentage'] ?? 100,
      missingCriteria: List<String>.from(json['missingCriteria'] ?? []),
      requiredDocuments: List<String>.from(json['requiredDocuments'] ?? []),
      missingDocuments: List<String>.from(json['missingDocuments'] ?? []),
      reasoning: json['reasoning'] ?? '',
      retrievedContextSnippets: List<String>.from(json['retrievedContextSnippets'] ?? []),
    );
  }
}
