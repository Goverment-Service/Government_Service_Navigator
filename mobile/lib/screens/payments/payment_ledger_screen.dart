import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../services/payment_service.dart';
import '../../models/ledger.dart';

class PaymentLedgerScreen extends StatefulWidget {
  final String token;
  final String paymentId;

  const PaymentLedgerScreen({
    super.key,
    required this.token,
    required this.paymentId,
  });

  @override
  State<PaymentLedgerScreen> createState() => _PaymentLedgerScreenState();
}

class _PaymentLedgerScreenState extends State<PaymentLedgerScreen> {
  PaymentLedger? _ledger;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = PaymentService(widget.token);
      final ledger = await service.getLedger(widget.paymentId);
      if (mounted) setState(() => _ledger = ledger);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Ledger'),
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
                onPressed: _loadLedger, child: const Text('Retry')),
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
          // Summary cards row
          Row(
            children: [
              Expanded(
                  child: _buildSummaryTile(
                      'Original', l.originalAmount, AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildSummaryTile(
                      'Refunded', l.totalRefunded, AppColors.warning)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildSummaryTile(
                      'Balance', l.runningBalance, AppColors.success)),
            ],
          ),
          const SizedBox(height: 16),

          // Status
          if (l.status != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 0.8),
              ),
              child: Row(
                children: [
                  const Text('Status',
                      style: TextStyle(
                          color: AppColors.secondaryLabel, fontSize: 15)),
                  const Spacer(),
                  Text(l.status!,
                      style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Entries
          const Text(
            'Ledger Entries',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
                letterSpacing: -0.3),
          ),
          const SizedBox(height: 12),
          if (l.entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No entries found.',
                    style: TextStyle(color: AppColors.secondaryLabel)),
              ),
            )
          else
            ...l.entries.map((entry) => _buildEntryRow(entry)),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LKR\n${amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildEntryRow(LedgerEntry entry) {
    final isCredit = entry.amount >= 0;
    final color = isCredit ? AppColors.success : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit
                  ? CupertinoIcons.arrow_down_circle
                  : CupertinoIcons.arrow_up_circle,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type ?? entry.description ?? 'Entry',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.dark),
                ),
                if (entry.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(entry.createdAt!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.secondaryLabel)),
                ],
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}LKR ${entry.amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
