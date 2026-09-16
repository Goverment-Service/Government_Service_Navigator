class RefundInfo {
  final int id;
  final int paymentId;
  final String status;
  final DateTime requestedAt;
  final double paymentAmount;
  final String currency;
  final double? refundAmount;
  final String? processingNotes;

  RefundInfo({
    required this.id,
    required this.paymentId,
    required this.status,
    required this.requestedAt,
    required this.paymentAmount,
    required this.currency,
    this.refundAmount,
    this.processingNotes,
  });

  factory RefundInfo.fromJson(Map<String, dynamic> json) => RefundInfo(
        id: json['id'] as int,
        paymentId: json['paymentId'] as int,
        status: json['status'] as String,
        requestedAt: DateTime.parse(json['requestedAt'] as String),
        paymentAmount: (json['paymentAmount'] as num).toDouble(),
        currency: json['currency'] as String,
        refundAmount: (json['refundAmount'] as num?)?.toDouble(),
        processingNotes: json['processingNotes'] as String?,
      );
}

class Payment {
  final int id;
  final String transactionReference;
  final String? applicationId;
  final String serviceName;
  final String method; // "BankTransfer" | "Stripe"
  final double amount;
  final String currency;
  final String status;
  final String? slipFileName;
  final DateTime? verifiedAt;
  final String? verificationNotes;
  final DateTime createdAt;
  final bool refundEligible;
  final RefundInfo? refund;

  Payment({
    required this.id,
    required this.transactionReference,
    this.applicationId,
    required this.serviceName,
    required this.method,
    required this.amount,
    required this.currency,
    required this.status,
    this.slipFileName,
    this.verifiedAt,
    this.verificationNotes,
    required this.createdAt,
    required this.refundEligible,
    this.refund,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as int,
        transactionReference: json['transactionReference'] as String,
        applicationId: json['applicationId'] as String?,
        serviceName: json['serviceName'] as String,
        method: json['method'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        status: json['status'] as String,
        slipFileName: json['slipFileName'] as String?,
        verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt'] as String) : null,
        verificationNotes: json['verificationNotes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        refundEligible: json['refundEligible'] as bool? ?? false,
        refund: json['refund'] != null ? RefundInfo.fromJson(json['refund'] as Map<String, dynamic>) : null,
      );
}
