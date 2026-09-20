class Payment {
  final String id;
  final String? applicationId;
  final double amount;
  final String? userEmail;
  final String? status;
  final String? paymentId;
  final String? checkoutUrl;

  const Payment({
    required this.id,
    this.applicationId,
    required this.amount,
    this.userEmail,
    this.status,
    this.paymentId,
    this.checkoutUrl,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? '',
      applicationId: json['applicationId']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      userEmail: json['userEmail'] as String?,
      status: json['status']?.toString(),
      paymentId: json['paymentId']?.toString(),
      checkoutUrl: json['checkoutUrl'] as String?,
    );
  }
}

/// Returned by POST /api/payments/checkout
class CheckoutResponse {
  final String paymentId;
  final String checkoutUrl;

  const CheckoutResponse({
    required this.paymentId,
    required this.checkoutUrl,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      paymentId: json['paymentId']?.toString() ?? '',
      checkoutUrl: json['checkoutUrl'] as String? ?? '',
    );
  }
}
