import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../services/refund_service.dart';
import '../../models/refund.dart';
import 'refund_detail_screen.dart';
import 'submit_refund_screen.dart';

class MyRefundsScreen extends StatefulWidget {
  final String token;

  const MyRefundsScreen({super.key, required this.token});

  @override
  State<MyRefundsScreen> createState() => _MyRefundsScreenState();
}

class _MyRefundsScreenState extends State<MyRefundsScreen> {
  List<Refund> _refunds = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRefunds();
  }

  Future<void> _loadRefunds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = RefundService(widget.token);
      final list = await service.myRefunds();
      if (mounted) setState(() => _refunds = list);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Refunds'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_left,
              color: AppColors.primary),
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.only(right: 16),
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) =>
                      SubmitRefundScreen(token: widget.token),
                ),
              );
            },
            child: const Icon(CupertinoIcons.add, color: AppColors.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 14))
          : _errorMessage != null
              ? _buildError()
              : _refunds.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
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
                onPressed: _loadRefunds, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.arrow_uturn_left,
                color: AppColors.warning, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('No refund requests',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark)),
          const SizedBox(height: 8),
          const Text('Tap + to submit a refund request.',
              style:
                  TextStyle(fontSize: 15, color: AppColors.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadRefunds,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _refunds.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final r = _refunds[index];
          final color = _statusColor(r.status);
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => RefundDetailScreen(
                    token: widget.token,
                    refundId: r.id,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 0.8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(CupertinoIcons.arrow_uturn_left,
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment: ${r.paymentId}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'LKR ${r.refundAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryLabel),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      r.status.label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.chevron_right,
                      size: 14, color: AppColors.secondaryLabel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
