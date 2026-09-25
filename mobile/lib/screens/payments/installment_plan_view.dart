import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payment_providers.dart';
import '../../providers/service_providers.dart';
import '../../models/installment_plan.dart';
import '../../widgets/status_badge.dart';
import 'bank_transfer_screen.dart';
import 'checkout_webview_screen.dart';

class InstallmentPlanView extends ConsumerStatefulWidget {
  final String? planId;
  final String? paymentId;

  const InstallmentPlanView({
    super.key,
    this.planId,
    this.paymentId,
  });

  @override
  ConsumerState<InstallmentPlanView> createState() => _InstallmentPlanViewState();
}

class _InstallmentPlanViewState extends ConsumerState<InstallmentPlanView> {
  String get _effectivePlanId {
    if (widget.planId != null && widget.planId!.isNotEmpty) {
      return widget.planId!;
    }
    if (widget.paymentId != null && widget.paymentId!.isNotEmpty) {
      return widget.paymentId!;
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic>) {
      if (routeArgs.containsKey('planId') && routeArgs['planId'] != null) {
        return routeArgs['planId'].toString();
      }
      if (routeArgs.containsKey('installmentPlanId') && routeArgs['installmentPlanId'] != null) {
        return routeArgs['installmentPlanId'].toString();
      }
      if (routeArgs.containsKey('paymentId') && routeArgs['paymentId'] != null) {
        return routeArgs['paymentId'].toString();
      }
    }
    return '';
  }

  /// Empty when opened from the menu: the provider then finds the citizen's plan.
  AsyncValue<InstallmentPlan> get _planState => ref.watch(installmentPlanProvider(_effectivePlanId));
  bool get _isLoading => _planState.isLoading;
  bool get _isNotFound => _planState.error is InstallmentPlanNotFound;
  String? get _errorMessage =>
      _planState.hasError ? _planState.error.toString().replaceAll('Exception: ', '') : null;
  InstallmentPlan? get _plan => _planState.value;

  Future<void> _fetchPlan() async {
    try {
      ref.invalidate(installmentPlanProvider(_effectivePlanId));
      await ref.read(installmentPlanProvider(_effectivePlanId).future);
    } catch (_) {
      // Shown from the provider's error state
    }
  }

  String? _payingInstallmentId;

  /// Pay Now: let the citizen choose online payment (Stripe) or bank transfer (receipt upload).
  Future<void> _payInstallment(Installment item) async {
    if (_payingInstallmentId != null) return;

    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pay installment #${item.installmentNumber}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('LKR ${item.amount.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.secondaryLabel)),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(CupertinoIcons.creditcard, color: AppColors.primary),
                title: const Text('Online payment'),
                subtitle: const Text('Pay by card through the secure payment gateway'),
                onTap: () => Navigator.of(sheetContext).pop('online'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(CupertinoIcons.building_2_fill, color: AppColors.primary),
                title: const Text('Bank transfer'),
                subtitle: const Text('Transfer to the department account and upload the receipt'),
                onTap: () => Navigator.of(sheetContext).pop('bank'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || method == null) return;

    if (method == 'online') {
      await _payOnline(item);
    } else {
      final submitted = await Navigator.of(context).push<bool>(
        CupertinoPageRoute(builder: (_) => BankTransferScreen(installment: item)),
      );
      if (!mounted || submitted != true) return;
      _showSnack('Receipt submitted. The installment will be marked paid once it is verified.', AppColors.success);
      await _fetchPlan();
    }
  }

  /// Opens the Stripe checkout for exactly this installment's amount, then confirms it with the backend.
  Future<void> _payOnline(Installment item) async {
    setState(() => _payingInstallmentId = item.id);
    final service = ref.read(installmentServiceProvider);
    try {
      final checkoutUrl = await service.startOnlinePayment(item.id);
      if (!mounted) return;

      final completed = await Navigator.of(context).push<bool>(
        CupertinoPageRoute(builder: (_) => CheckoutWebViewScreen(checkoutUrl: checkoutUrl)),
      );
      if (!mounted) return;
      if (completed != true) {
        _showSnack('Online payment was not completed.', AppColors.warning);
        return;
      }

      await service.confirmOnlinePayment(item.id);
      if (!mounted) return;
      _showSnack('Installment paid successfully!', AppColors.success);
      await _fetchPlan();
    } catch (e) {
      _showSnack('Payment failed: ${e.toString().replaceAll('Exception: ', '')}', AppColors.danger);
    } finally {
      if (mounted) setState(() => _payingInstallmentId = null);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '—';
    try {
      final parsed = DateTime.parse(rawDate);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[parsed.month - 1]} ${parsed.day.toString().padLeft(2, '0')}, ${parsed.year}';
    } catch (_) {
      return rawDate.contains('T') ? rawDate.split('T')[0] : rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Installment Schedule'),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(radius: 14),
            SizedBox(height: 12),
            Text(
              'Loading installment plan...',
              style: TextStyle(
                color: AppColors.secondaryLabel,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_isNotFound) {
      return _buildEmptyState();
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: AppColors.danger,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                borderRadius: BorderRadius.circular(12),
                onPressed: _fetchPlan,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final plan = _plan;
    if (plan == null) {
      return _buildEmptyState();
    }

    int? nextUpcomingIndex;
    for (int i = 0; i < plan.installments.length; i++) {
      final inst = plan.installments[i];
      final statusStr = inst.status?.toLowerCase() ?? 'pending';
      final isPaid = statusStr == 'paid' || statusStr == 'completed';
      if (!isPaid) {
        nextUpcomingIndex = i;
        break;
      }
    }

    return RefreshIndicator(
      onRefresh: _fetchPlan,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Summary Header Card
          _buildSummaryHeaderCard(plan),
          const SizedBox(height: 24),

          // Schedule Section Title
          const Text(
            'Payment Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Installments List
          if (plan.installments.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Center(
                child: Text(
                  'No installments listed for this plan.',
                  style: TextStyle(color: AppColors.secondaryLabel),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plan.installments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = plan.installments[index];
                final isNextUpcoming = (index == nextUpcomingIndex);
                return _buildInstallmentTile(item, isNextUpcoming: isNextUpcoming);
              },
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildSummaryHeaderCard(InstallmentPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plan ID: ${plan.id}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryLabel,
                ),
              ),
              StatusBadge(status: plan.status ?? 'Active', showDot: true),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Total Plan Amount',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'LKR ${plan.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(CupertinoIcons.calendar, size: 16, color: AppColors.secondaryLabel),
              const SizedBox(width: 6),
              Text(
                '${plan.numberOfInstallments} Total Installments',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dark,
                ),
              ),
              if (plan.paymentId.isNotEmpty) ...[
                const Spacer(),
                Text(
                  'Payment #${plan.paymentId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  bool _checkIsOverdue(Installment item) {
    final statusStr = item.status?.toLowerCase() ?? '';
    if (statusStr == 'overdue') return true;
    if (statusStr == 'paid' || statusStr == 'completed' || statusStr == 'pendingverification') return false;
    if (item.dueDate != null && item.dueDate!.isNotEmpty) {
      try {
        final due = DateTime.parse(item.dueDate!);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dueDateOnly = DateTime(due.year, due.month, due.day);
        return dueDateOnly.isBefore(today);
      } catch (_) {}
    }
    return false;
  }

  Widget _buildInstallmentTile(Installment item, {required bool isNextUpcoming}) {
    final statusStr = item.status?.toLowerCase() ?? 'pending';
    final isPaid = statusStr == 'paid' || statusStr == 'completed';
    final isUnderReview = statusStr == 'pendingverification';
    final isOverdue = _checkIsOverdue(item);

    // Dynamic styles based on state
    Color tileBgColor = AppColors.cardBg;
    Color borderColor = AppColors.divider;
    double borderWidth = 0.8;

    if (isPaid) {
      tileBgColor = AppColors.cardBg.withValues(alpha: 0.65);
      borderColor = AppColors.divider.withValues(alpha: 0.5);
    } else if (isOverdue) {
      tileBgColor = AppColors.danger.withValues(alpha: 0.05);
      borderColor = AppColors.danger.withValues(alpha: 0.4);
      borderWidth = 1.2;
    } else if (isNextUpcoming) {
      tileBgColor = AppColors.primary.withValues(alpha: 0.05);
      borderColor = AppColors.primary;
      borderWidth = 1.5;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tileBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Index Badge Circle / Muted Checkmark
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.success.withValues(alpha: 0.12)
                  : isOverdue
                      ? AppColors.danger.withValues(alpha: 0.12)
                      : isNextUpcoming
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isPaid
                  ? const Icon(
                      CupertinoIcons.checkmark,
                      color: AppColors.success,
                      size: 20,
                    )
                  : Text(
                      '#${item.installmentNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isNextUpcoming
                            ? Colors.white
                            : isOverdue
                                ? AppColors.danger
                                : AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'LKR ${item.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isPaid ? AppColors.secondaryLabel : AppColors.dark,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.secondaryLabel,
                      ),
                    ),
                    if (isNextUpcoming && !isPaid) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEXT DUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isOverdue
                          ? CupertinoIcons.exclamationmark_circle_fill
                          : CupertinoIcons.clock,
                      size: 13,
                      color: isOverdue
                          ? AppColors.danger
                          : AppColors.secondaryLabel,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_formatDate(item.dueDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                        color: isOverdue ? AppColors.danger : AppColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
                if (item.paidDate != null && item.paidDate!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Paid on: ${_formatDate(item.paidDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status Badge & Action Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusBadge(
                status: isOverdue ? 'Overdue' : (isUnderReview ? 'Under Review' : (item.status ?? 'Pending')),
                showDot: isOverdue || isNextUpcoming,
              ),
              if (isUnderReview) ...[
                const SizedBox(height: 8),
                const Text('Receipt submitted',
                    style: TextStyle(fontSize: 12, color: AppColors.secondaryLabel)),
              ] else if (!isPaid) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: _payingInstallmentId == item.id.toString()
                        ? null
                        : () => _payInstallment(item),
                    child: _payingInstallmentId == item.id.toString()
                        ? const CupertinoActivityIndicator(color: Colors.white, radius: 7)
                        : const Text(
                            'Pay Now',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _fetchPlan,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.doc_text_search,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Installment Plan Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'No installment plan for this payment',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


