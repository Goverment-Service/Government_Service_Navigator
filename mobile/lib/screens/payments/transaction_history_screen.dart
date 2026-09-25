import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payment_providers.dart';
import '../../models/payment.dart';
import '../../widgets/status_badge.dart';
import 'payment_ledger_screen.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  AsyncValue<List<Payment>> get _paymentsState => ref.watch(myPaymentsProvider);
  bool get _isLoading => _paymentsState.isLoading;
  String? get _errorMessage =>
      _paymentsState.hasError ? _paymentsState.error.toString().replaceAll('Exception: ', '') : null;
  List<Payment> get _payments => _paymentsState.value ?? const [];

  Future<void> _loadPayments() async {
    try {
      ref.invalidate(myPaymentsProvider);
      await ref.read(myPaymentsProvider.future);
    } catch (_) {
      // Shown from the provider's error state
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(raw);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return raw.contains('T') ? raw.split('T')[0] : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_left, color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_payments.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final p = _payments[index];
          return _buildPaymentTile(p);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(radius: 14),
          SizedBox(height: 12),
          Text(
            'Loading transactions...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Failed to load transaction history.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 14),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _loadPayments,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _loadPayments,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.creditcard_fill,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your payment history and transaction receipts will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.secondaryLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(Payment p) {
    final methodStr = p.method ?? 'Online Payment';
    final displayDate = p.paidDate ?? p.createdDate;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => PaymentLedgerScreen(
                  paymentId: p.id,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Payment Method Icon Bubble
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.creditcard,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Main Info Column: Amount, Method, Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LKR ${p.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            methodStr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: AppColors.secondaryLabel)),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(displayDate),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge & Arrow
                StatusBadge(status: p.status ?? 'Pending'),
                const SizedBox(width: 6),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.secondaryLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

