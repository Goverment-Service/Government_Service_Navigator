import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payment_providers.dart';
import '../../models/payment.dart';
import 'payment_confirm_screen.dart';
import 'checkout_screen.dart';

class MyPaymentsScreen extends ConsumerStatefulWidget {
  const MyPaymentsScreen({super.key});

  @override
  ConsumerState<MyPaymentsScreen> createState() => _MyPaymentsScreenState();
}

class _MyPaymentsScreenState extends ConsumerState<MyPaymentsScreen> {
  AsyncValue<List<Payment>> get _paymentsState => ref.watch(myPaymentsProvider);
  bool get _isLoading => _paymentsState.isLoading;
  String? get _errorMessage => _paymentsState.hasError ? _paymentsState.error.toString() : null;
  List<Payment> get _payments => _paymentsState.value ?? const [];

  Future<void> _loadPayments() async {
    try {
      ref.invalidate(myPaymentsProvider);
      await ref.read(myPaymentsProvider.future);
    } catch (_) {
      // Shown from the provider's error state
    }
  }

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
        title: const Text('My Payments'),
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
                  builder: (_) => const CheckoutScreen(),
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
              : _payments.isEmpty
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
                onPressed: _loadPayments, child: const Text('Retry')),
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
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.creditcard,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('No payments yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark)),
          const SizedBox(height: 8),
          const Text('Tap + to make your first payment.',
              style: TextStyle(fontSize: 15, color: AppColors.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadPayments,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final p = _payments[index];
          final color = _statusColor(p.status);
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => PaymentConfirmScreen(
                    paymentId: p.id,
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
                    child:
                        Icon(CupertinoIcons.creditcard, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.applicationId ?? 'Payment',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'LKR ${p.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.secondaryLabel),
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
                      p.status ?? '—',
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
