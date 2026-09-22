import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../services/installment_service.dart';
import '../../models/installment_plan.dart';
import '../../widgets/status_badge.dart';

class InstallmentPlanView extends StatefulWidget {
  final String? token;
  final String? planId;
  final String? paymentId;

  const InstallmentPlanView({
    super.key,
    this.token,
    this.planId,
    this.paymentId,
  });

  @override
  State<InstallmentPlanView> createState() => _InstallmentPlanViewState();
}

class _InstallmentPlanViewState extends State<InstallmentPlanView> {
  bool _isLoading = true;
  String? _errorMessage;
  InstallmentPlan? _plan;

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
    return 'PLAN-1001';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPlan();
    });
  }

  Future<void> _fetchPlan() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final targetId = _effectivePlanId;

    try {
      final service = InstallmentService(_effectiveToken);
      final plan = await service.getInstallmentPlan(targetId);

      if (!mounted) return;
      setState(() {
        _plan = plan;
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
              Text(
                'Failed to load plan',
                style: const TextStyle(
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
      return const Center(child: Text('No installment plan data found.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Plan Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
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
          ),
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
          if (plan.installments.isEmpty) ...[
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
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plan.installments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = plan.installments[index];
                return _buildInstallmentTile(item);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstallmentTile(Installment item) {
    final isPaid = item.status?.toLowerCase() == 'paid' || item.status?.toLowerCase() == 'completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid ? AppColors.success.withValues(alpha: 0.3) : AppColors.divider,
          width: isPaid ? 1.0 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Index Badge Circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${item.installmentNumber}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isPaid ? AppColors.success : AppColors.primary,
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
                Text(
                  'LKR ${item.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.clock,
                      size: 13,
                      color: AppColors.secondaryLabel,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_formatDate(item.dueDate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryLabel,
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

          // Status Badge
          StatusBadge(status: item.status ?? 'Pending'),
        ],
      ),
    );
  }
}

