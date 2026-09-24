class IntakePlanModel {
  final String recommendedService;
  final List<String> requiredDocuments;
  final List<String> stepByStepPlan;
  final List<String> retrievedContextSnippets;

  IntakePlanModel({
    required this.recommendedService,
    required this.requiredDocuments,
    required this.stepByStepPlan,
    required this.retrievedContextSnippets,
  });

  factory IntakePlanModel.fromJson(Map<String, dynamic> json) {
    return IntakePlanModel(
      recommendedService: json['recommendedService'] ?? 'Unknown Service',
      requiredDocuments: List<String>.from(json['requiredDocuments'] ?? []),
      stepByStepPlan: List<String>.from(json['stepByStepPlan'] ?? []),
      retrievedContextSnippets:
          List<String>.from(json['retrievedContextSnippets'] ?? []),
    );
  }
}
