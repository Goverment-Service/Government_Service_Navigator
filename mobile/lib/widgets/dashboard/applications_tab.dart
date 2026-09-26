import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/verification_models.dart';
import '../../screens/verification_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../screens/payments/installment_plan_view.dart';
import '../../screens/payments/transaction_history_screen.dart';
import '../../screens/payments/payment_screen.dart';
import '../../screens/refunds/refund_request_screen.dart';
import '../../screens/refunds/my_refunds_screen.dart';
import '../../screens/analytics/approval_likelihood_screen.dart';
import '../../screens/notifications_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/application_providers.dart';
import '../../providers/session_provider.dart';

class ApplicationsTab extends ConsumerStatefulWidget {
  const ApplicationsTab({super.key});

  @override
  ConsumerState<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends ConsumerState<ApplicationsTab> {
  String _selectedFilter = 'All'; // 'All', 'In Review', 'Approved', 'Needs Action'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ApplicationItemModel> get _applications => ref.watch(myApplicationsProvider).value ?? const [];

  /// Reloads the applications and the notification badge.
  Future<void> _loadApplications() async {
    ref.invalidate(notificationsProvider);
    ref.invalidate(myApplicationsProvider);
    await ref.read(myApplicationsProvider.future);
  }

  Future<void> _openNotifications() async {
    if (!ref.read(sessionProvider).isSignedIn) return;
    await Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const NotificationsScreen()));
    if (mounted) await _loadApplications();
  }

  Future<void> _openInstallments(ApplicationItemModel app) async {
    final plan = app.installmentPlan;
    if (plan == null) return;
    await Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => InstallmentPlanView(planId: plan.planId),
    ));
    if (mounted) await _loadApplications();
  }

  List<ApplicationItemModel> get _filteredApplications {
    return _applications.where((app) {
      if (_selectedFilter == 'In Review' && app.status.toLowerCase() != 'pending') {
        return false;
      }
      if (_selectedFilter == 'Approved' && app.status.toLowerCase() != 'approved') {
        return false;
      }
      if (_selectedFilter == 'Needs Action' &&
          app.status.toLowerCase() != 'revised' &&
          app.status.toLowerCase() != 'revision requested' &&
          app.status.toLowerCase() != 'rejected') {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesRef = app.referenceNumber.toLowerCase().contains(query);
        final matchesService = app.serviceName.toLowerCase().contains(query);
        final matchesCategory = app.category.toLowerCase().contains(query);
        return matchesRef || matchesService || matchesCategory;
      }
      return true;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'revised':
      case 'revision requested':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.secondaryLabel;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Verified';
      case 'revised':
      case 'revision requested':
        return 'Action Required';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'In Review';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return CupertinoIcons.checkmark_seal_fill;
      case 'revised':
      case 'revision requested':
        return CupertinoIcons.exclamationmark_triangle_fill;
      case 'rejected':
        return CupertinoIcons.xmark_circle_fill;
      case 'cancelled':
        return CupertinoIcons.nosign;
      default:
        return CupertinoIcons.clock_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(myApplicationsProvider).isLoading;
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'My Applications & Verification',
          style: TextStyle(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              child: const Icon(CupertinoIcons.bell, color: AppColors.primary),
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.primary),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Search Bar & Status Chips
            Container(
              color: AppColors.cardBg,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Column(
                children: [
                  CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Search by reference ID or service...',
                    onChanged: (val) => setState(() => _searchQuery = val),
                    onSubmitted: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip('All', _applications.length),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'In Review',
                          _applications.where((a) => a.status.toLowerCase() == 'pending').length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Approved',
                          _applications.where((a) => a.status.toLowerCase() == 'approved').length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Needs Action',
                          _applications.where((a) =>
                              a.status.toLowerCase() == 'revised' ||
                              a.status.toLowerCase() == 'revision requested' ||
                              a.status.toLowerCase() == 'rejected').length,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            // 2. Application List
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoading
                  ? const Center(child: CupertinoActivityIndicator(radius: 14))
                  : _filteredApplications.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredApplications.length,
                          itemBuilder: (context, index) {
                            final app = _filteredApplications[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: _buildTrackingCard(app),
                            );
                          },
                        ),
            ),

            // 3. Payments Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Payments'),
                  const SizedBox(height: 10),
                  _buildActionTile(
                    context: context,
                    icon: CupertinoIcons.doc_text,
                    iconColor: AppColors.success,
                    title: 'Transaction History',
                    subtitle: 'View payment history & ledger receipts',
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => const TransactionHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // 4. Refunds Section
                  _buildSectionHeader('Refunds'),
                  const SizedBox(height: 10),
                  _buildActionTile(
                    context: context,
                    icon: CupertinoIcons.plus_circle,
                    iconColor: AppColors.danger,
                    title: 'Request a Refund',
                    subtitle: 'Submit a new refund request for a payment',
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => const RefundRequestScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildActionTile(
                    context: context,
                    icon: CupertinoIcons.arrow_uturn_left,
                    iconColor: AppColors.warning,
                    title: 'My Refund Requests',
                    subtitle: 'Track status of your refund requests',
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => const MyRefundsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // 5. Analytics Section
                  _buildSectionHeader('Analytics'),
                  const SizedBox(height: 10),
                  _buildActionTile(
                    context: context,
                    icon: CupertinoIcons.chart_bar_fill,
                    iconColor: AppColors.primary,
                    title: 'Approval Likelihood',
                    subtitle: 'Predict your application approval chance',
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => const ApprovalLikelihoodScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLabel,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.secondaryLabel),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 14, color: AppColors.secondaryLabel),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String title, int count) {
    final isSelected = _selectedFilter == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.secondaryLabel,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.dark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Installment progress for an application paid in installments, with a button to its payment schedule.
  Widget _buildInstallmentStrip(ApplicationItemModel app) {
    final plan = app.installmentPlan!;
    final due = plan.nextDueDate;
    final String detail;
    final Color color;

    if (plan.status.toLowerCase() == 'cancelled') {
      detail = 'Installment plan cancelled — an installment was not paid by its due date';
      color = AppColors.danger;
    } else if (plan.status.toLowerCase() == 'completed' || due == null) {
      detail = 'All ${plan.numberOfInstallments} installments paid';
      color = AppColors.success;
    } else if (plan.nextStatus?.toLowerCase() == 'pendingverification') {
      detail = 'Receipt under review · ${plan.paidCount}/${plan.numberOfInstallments} paid';
      color = AppColors.warning;
    } else {
      final dueText = '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}';
      final daysLeft = DateTime(due.year, due.month, due.day)
          .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
          .inDays;
      detail = 'Next LKR ${plan.nextAmount?.toStringAsFixed(2) ?? '—'} due $dueText · '
          '${plan.paidCount}/${plan.numberOfInstallments} paid';
      color = daysLeft <= 3 ? AppColors.danger : AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.calendar, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(detail, style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600))),
          if (plan.isActive)
            TextButton(
              onPressed: () => _openInstallments(app),
              child: const Text('Pay Installments'),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard(ApplicationItemModel app) {
    final statusColor = _getStatusColor(app.status);
    final reviews = app.verificationTask?.reviews ?? [];
    final latestReview = reviews.isNotEmpty ? reviews.last : null;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<ApplicationItemModel>(
          context,
          CupertinoPageRoute(
            builder: (context) => VerificationDetailScreen(application: app),
          ),
        );
        if (result != null) {
          _loadApplications();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
                Row(
                  children: [
                    const Icon(CupertinoIcons.doc_text_fill, size: 14, color: AppColors.secondaryLabel),
                    const SizedBox(width: 5),
                    Text(
                      app.referenceNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLabel,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(app.status), size: 12, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        _getStatusDisplay(app.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              app.serviceName,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              app.category,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.secondaryLabel,
              ),
            ),
            if (latestReview != null && latestReview.comments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(left: BorderSide(color: statusColor, width: 3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        latestReview.comments,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.dark,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (app.installmentPlan != null) ...[
              const SizedBox(height: 12),
              _buildInstallmentStrip(app),
            ],
            if (app.maxStages > 1) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: app.stageStatus == 'AwaitingFeePayment'
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: app.stageStatus == 'AwaitingFeePayment'
                        ? AppColors.warning.withValues(alpha: 0.3)
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Stage ${app.currentStage}/${app.maxStages}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        app.stageStatus == 'AwaitingFeePayment'
                            ? 'Fee Payment Required'
                            : ((app.stageStatus == 'StageApproved' || app.stageStatus.endsWith('Unlocked'))
                                ? 'Stage ${app.currentStage} Ready • ${app.currentDepartment ?? 'Next Dept'}'
                                : (app.stageStatus == 'Completed'
                                    ? 'All Milestones Cleared'
                                    : (app.currentDepartment != null
                                        ? 'Reviewing: ${app.currentDepartment}'
                                        : 'In Review'))),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: (app.stageStatus == 'AwaitingFeePayment' || app.stageStatus == 'StageApproved' || app.stageStatus.endsWith('Unlocked')) ? FontWeight.w700 : FontWeight.w500,
                          color: app.stageStatus == 'AwaitingFeePayment'
                              ? AppColors.warning
                              : ((app.stageStatus == 'StageApproved' || app.stageStatus.endsWith('Unlocked')) ? AppColors.success : AppColors.dark),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (app.stageStatus == 'StageApproved' || app.stageStatus.endsWith('Unlocked'))
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () => Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => VerificationDetailScreen(application: app),
                          ),
                        ),
                        child: const Text('Fill Form', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    if (app.stageStatus == 'AwaitingFeePayment')
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => PaymentScreen(
                                applicationId: app.applicationId.toString(),
                                amount: app.amount > 0 ? app.amount : 2500.0,
                                userEmail: app.userEmail,
                                popOnPaid: true,
                              ),
                            ),
                          );
                          _loadApplications();
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.creditcard_fill, size: 11, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Pay Fee', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Submitted ${app.submittedDate.year}-${app.submittedDate.month.toString().padLeft(2, '0')}-${app.submittedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryLabel,
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      'View Verification',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text_search,
              size: 56,
              color: AppColors.secondaryLabel.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Applications Found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your status filter or search keywords.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}