/// Integer values as sent by the backend.
/// 0=Pending, 1=Approved, 2=Rejected, 3=Processing, 4=Completed, 5=Failed
enum RefundStatus {
  pending,
  approved,
  rejected,
  processing,
  completed,
  failed;

  static RefundStatus fromInt(int value) {
    switch (value) {
      case 0:
        return RefundStatus.pending;
      case 1:
        return RefundStatus.approved;
      case 2:
        return RefundStatus.rejected;
      case 3:
        return RefundStatus.processing;
      case 4:
        return RefundStatus.completed;
      case 5:
        return RefundStatus.failed;
      default:
        return RefundStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case RefundStatus.pending:
        return 'Pending';
      case RefundStatus.approved:
        return 'Approved';
      case RefundStatus.rejected:
        return 'Rejected';
      case RefundStatus.processing:
        return 'Processing';
      case RefundStatus.completed:
        return 'Completed';
      case RefundStatus.failed:
        return 'Failed';
    }
  }
}

class Refund {
  final String id;
  final String paymentId;
  final double refundAmount;
  final String? reason;
  final RefundStatus status;

  const Refund({
    required this.id,
    required this.paymentId,
    required this.refundAmount,
    this.reason,
    required this.status,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: json['id']?.toString() ?? '',
      paymentId: json['paymentId']?.toString() ?? '',
      refundAmount: (json['refundAmount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String?,
      status: RefundStatus.fromInt(
        (json['status'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
