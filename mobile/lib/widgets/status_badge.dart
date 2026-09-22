import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/refund.dart';

class StatusBadge extends StatelessWidget {
  final dynamic status;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.showDot = false,
  });

  String get _statusText {
    if (status == null) return '—';
    if (status is RefundStatus) {
      return (status as RefundStatus).label;
    }
    if (status is int) {
      return RefundStatus.fromInt(status as int).label;
    }
    final str = status.toString().trim();
    if (str.isEmpty) return '—';
    return str;
  }

  Color get _badgeColor {
    if (status == null) return AppColors.secondaryLabel;

    if (status is RefundStatus) {
      switch (status as RefundStatus) {
        case RefundStatus.approved:
        case RefundStatus.completed:
          return AppColors.success;
        case RefundStatus.pending:
        case RefundStatus.processing:
          return AppColors.warning;
        case RefundStatus.rejected:
        case RefundStatus.failed:
          return AppColors.danger;
      }
    }

    if (status is int) {
      return _getColorFromRefundStatus(RefundStatus.fromInt(status as int));
    }

    final key = status.toString().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

    switch (key) {
      case 'approved':
      case 'paid':
      case 'completed':
      case 'verified':
      case 'active':
      case 'success':
        return AppColors.success;

      case 'pending':
      case 'processing':
      case 'pendingverification':
      case 'underreview':
      case 'inreview':
        return AppColors.warning;

      case 'rejected':
      case 'failed':
      case 'overdue':
      case 'cancelled':
      case 'canceled':
      case 'denied':
        return AppColors.danger;

      case 'draft':
      case 'new':
      case 'submitted':
      case 'open':
        return AppColors.primary;

      default:
        return AppColors.secondaryLabel;
    }
  }

  Color _getColorFromRefundStatus(RefundStatus s) {
    switch (s) {
      case RefundStatus.approved:
      case RefundStatus.completed:
        return AppColors.success;
      case RefundStatus.pending:
      case RefundStatus.processing:
        return AppColors.warning;
      case RefundStatus.rejected:
      case RefundStatus.failed:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            _statusText,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
