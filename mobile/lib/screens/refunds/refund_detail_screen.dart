import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../services/refund_service.dart';
import '../../models/refund.dart';

class RefundDetailScreen extends StatefulWidget {
  final String token;
  final String refundId;

  const RefundDetailScreen({
    super.key,
    required this.token,
    required this.refundId,
  });

  @override
  State<RefundDetailScreen> createState() => _RefundDetailScreenState();
}

class _RefundDetailScreenState extends State<RefundDetailScreen> {
  Refund? _refund;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRefund();
  }

  Future<void> _loadRefund() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = RefundService(widget.token);
      final refund = await service.getRefund(widget.refundId);
      if (mounted) setState(() => _refund = refund);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(RefundStatus status) {
    switch (status) {
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

  IconData _statusIcon(RefundStatus status) {
    switch (status) {
      case RefundStatus.approved:
      case RefundStatus.completed:
        return CupertinoIcons.checkmark_seal_fill;
      case RefundStatus.pending:
        return CupertinoIcons.clock_fill;
      case RefundStatus.processing:
        return CupertinoIcons.arrow_2_circlepath;
      case RefundStatus.rejected:
      case RefundStatus.failed:
        return CupertinoIcons.xmark_seal_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Refund Details'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_left,
              color: AppColors.primary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 14))
          : _errorMessage != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle,
                color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.secondaryLabel)),
            const SizedBox(height: 20),
            CupertinoButton.filled(
                onPressed: _loadRefund, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final r = _refund!;
    final color = _statusColor(r.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status hero
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider, width: 0.8),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(r.status), color: color, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  r.status.label,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 6),
                Text('Refund ID: ${r.id}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.secondaryLabel)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Detail rows
          _buildDetailCard([
            _detailRow('Payment ID', r.paymentId),
            _detailRow(
                'Refund Amount', 'LKR ${r.refundAmount.toStringAsFixed(2)}'),
            if (r.reason != null && r.reason!.isNotEmpty)
              _detailRow('Reason', r.reason!),
          ]),
        ],
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          return Column(
            children: [
              rows[i],
              if (i < rows.length - 1)
                const Divider(
                    height: 1, color: AppColors.divider, indent: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.secondaryLabel, fontSize: 15)),
          const SizedBox(width: 20),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppColors.dark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
