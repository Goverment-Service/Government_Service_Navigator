class ApprovalLikelihood {
  final int approvalLikelihoodPercent;
  final int sampleSize;

  const ApprovalLikelihood({
    required this.approvalLikelihoodPercent,
    required this.sampleSize,
  });

  factory ApprovalLikelihood.fromJson(Map<String, dynamic> json) {
    return ApprovalLikelihood(
      approvalLikelihoodPercent:
          (json['approvalLikelihoodPercent'] as num?)?.toInt() ?? 0,
      sampleSize: (json['sampleSize'] as num?)?.toInt() ?? 0,
    );
  }
}
