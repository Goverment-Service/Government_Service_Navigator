import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../services/payment_service.dart';
import '../../models/ledger.dart';
import '../../widgets/status_badge.dart';

class PaymentLedgerScreen extends StatefulWidget {
  final String? token;
  final String? paymentId;

  const PaymentLedgerScreen({
    super.key,
    this.token,
    this.paymentId,
  });

  @override
  State<PaymentLedgerScreen> createState() => _PaymentLedgerScreenState();
}

class _PaymentLedgerScreenState extends State<PaymentLedgerScreen> {
  PaymentLedger? _ledger;
  bool _isLoading = true;
  String? _errorMessage;

  String get _effectiveToken {
    if (widget.token != null && widget.token!.isNotEmpty) {
      return widget.token!;
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic> && routeArgs.containsKey('token')) {
      return routeArgs['token']?.toString() ?? '';
    }
    return '';
  }

  String get _effectivePaymentId {
    if (widget.paymentId != null && widget.paymentId!.isNotEmpty) {
      return widget.paymentId!;
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic>) {
      if (routeArgs.containsKey('paymentId')) {
        return routeArgs['paymentId']?.toString() ?? '';
      }
      if (routeArgs.containsKey('id')) {
        return routeArgs['id']?.toString() ?? '';
      }
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLedger();
    });
  }

  Future<void> _loadLedger() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final targetId = _effectivePaymentId;
    if (targetId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No payment ID specified.';
      });
      return;
    }

    try {
      final service = PaymentService(_effectiveToken);
      final ledger = await service.getLedger(targetId);
      if (!mounted) return;
      setState(() {
        _ledger = ledger;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmt = amount.abs();
    final parts = absAmt.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }
    final formattedStr = '${buffer.toString()}.$decimalPart';
    return isNegative ? '-LKR $formattedStr' : 'LKR $formattedStr';
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
        title: const Text('Payment Ledger Receipt'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_left, color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : _errorMessage != null
                ? _buildError()
                : _buildContent(),
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
            Text(
              _errorMessage ?? 'Failed to load ledger details.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 14),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _loadLedger,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final l = _ledger!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment #${l.paymentId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                    if (l.status != null)
                      StatusBadge(status: l.status!),
                  ],
                ),
                const SizedBox(height: 16),

                // Grid: Original Amount, Total Refunded, Running Balance
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        label: 'Original',
                        amount: l.originalAmount,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryMetric(
                        label: 'Refunded',
                        amount: l.totalRefunded,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryMetric(
                        label: 'Balance',
                        amount: l.runningBalance,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Ledger Entries Section
          const Text(
            'Receipt Statement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          if (l.entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Center(
                child: Text('No ledger entries recorded.'),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dark.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(l.entries.length, (index) {
                  final entry = l.entries[index];
                  final isLast = index == l.entries.length - 1;
                  return Column(
                    children: [
                      _buildEntryRow(entry),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          color: AppColors.divider,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryRow(LedgerEntry entry) {
    final entryTypeLower = (entry.type ?? '').toLowerCase();
    final descLower = (entry.description ?? '').toLowerCase();
    final isRefund = entryTypeLower.contains('refund') ||
        descLower.contains('refund') ||
        entry.amount < 0;

    final color = isRefund ? AppColors.warning : AppColors.success;
    final icon = isRefund ? CupertinoIcons.arrow_uturn_left : CupertinoIcons.arrow_down_circle;

    final displayDate = _formatDate(entry.createdAt ?? entry.date);
    final descriptionStr = entry.description ?? entry.type ?? 'Ledger Entry';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descriptionStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isRefund ? '-' : '+'}${_formatCurrency(entry.amount.abs())}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}
