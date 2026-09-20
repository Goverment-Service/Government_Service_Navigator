class LedgerEntry {
  final String? id;
  final String? type;
  final double amount;
  final String? description;
  final String? createdAt;

  const LedgerEntry({
    this.id,
    this.type,
    required this.amount,
    this.description,
    this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id']?.toString(),
      type: json['type']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class PaymentLedger {
  final double originalAmount;
  final double totalRefunded;
  final double runningBalance;
  final String? status;
  final List<LedgerEntry> entries;

  const PaymentLedger({
    required this.originalAmount,
    required this.totalRefunded,
    required this.runningBalance,
    this.status,
    required this.entries,
  });

  factory PaymentLedger.fromJson(Map<String, dynamic> json) {
    final rawList = json['entries'] as List<dynamic>? ?? [];
    return PaymentLedger(
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
      totalRefunded: (json['totalRefunded'] as num?)?.toDouble() ?? 0.0,
      runningBalance: (json['runningBalance'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString(),
      entries: rawList
          .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
