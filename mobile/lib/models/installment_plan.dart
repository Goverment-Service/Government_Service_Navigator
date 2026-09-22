class Installment {
  final String id;
  final int installmentNumber;
  final double amount;
  final String? dueDate;
  final String? status;
  final String? paidDate;

  const Installment({
    required this.id,
    required this.installmentNumber,
    required this.amount,
    this.dueDate,
    this.status,
    this.paidDate,
  });

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id']?.toString() ?? '',
      installmentNumber: (json['installmentNumber'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['dueDate'] as String?,
      status: json['status']?.toString(),
      paidDate: json['paidDate'] as String?,
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

