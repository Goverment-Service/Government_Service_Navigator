class Installment {
  final String id;
  final String? dueDate;
  final double amount;
  final String? status;

  const Installment({
    required this.id,
    this.dueDate,
    required this.amount,
    this.status,
  });

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id']?.toString() ?? '',
      dueDate: json['dueDate'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString(),
    );
  }
}

class InstallmentPlan {
  final String id;
  final String paymentId;
  final int numberOfInstallments;
  final double totalAmount;
  final String? status;
  final List<Installment> installments;

  const InstallmentPlan({
    required this.id,
    required this.paymentId,
    required this.numberOfInstallments,
    required this.totalAmount,
    this.status,
    required this.installments,
  });

  factory InstallmentPlan.fromJson(Map<String, dynamic> json) {
    final rawList = json['installments'] as List<dynamic>? ?? [];
    return InstallmentPlan(
      id: json['id']?.toString() ?? '',
      paymentId: json['paymentId']?.toString() ?? '',
      numberOfInstallments:
          (json['numberOfInstallments'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString(),
      installments:
          rawList.map((e) => Installment.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
