import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payment_providers.dart';
import '../../models/payment.dart';
import 'payment_ledger_screen.dart';

class PaymentConfirmScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final String? checkoutUrl;

  const PaymentConfirmScreen({
    super.key,
    required this.paymentId,
    this.checkoutUrl,
  });

  @override
  ConsumerState<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends ConsumerState<PaymentConfirmScreen> {
  AsyncValue<Payment> get _paymentState => ref.watch(paymentConfirmationProvider(widget.paymentId));
  bool get _isLoading => _paymentState.isLoading;
  String? get _errorMessage => _paymentState.hasError ? _paymentState.error.toString() : null;
  Payment? get _payment => _paymentState.value;

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.danger;
      default:
        return AppColors.secondaryLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
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
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryLabel),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: () => ref.invalidate(paymentConfirmationProvider(widget.paymentId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final p = _payment!;
    final color = _statusColor(p.status);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status badge hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
                  child: Icon(
                    p.status?.toLowerCase() == 'completed' ||
                            p.status?.toLowerCase() == 'paid'
                        ? CupertinoIcons.checkmark_seal_fill
                        : CupertinoIcons.clock_fill,
                    color: color,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  p.status ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Payment ID: ${p.id}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.secondaryLabel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details card
          _buildDetailCard([
            _detailRow('Application ID', p.applicationId ?? '—'),
            _detailRow('Amount', 'LKR ${p.amount.toStringAsFixed(2)}'),
            _detailRow('Email', p.userEmail ?? '—'),
          ]),
          const SizedBox(height: 20),

          if (widget.checkoutUrl != null && widget.checkoutUrl!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.link,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.checkoutUrl!,
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // View Ledger button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: CupertinoButton.filled(
              borderRadius: BorderRadius.circular(14),
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => PaymentLedgerScreen(
                      paymentId: p.id,
                    ),
                  ),
                );
              },
              child: const Text(
                'View Ledger',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
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
                const Divider(height: 1, color: AppColors.divider, indent: 16),
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
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.secondaryLabel, fontSize: 15)),
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
