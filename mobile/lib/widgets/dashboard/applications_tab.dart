import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../screens/payments/payment_screen.dart';
import '../../screens/payments/installment_plan_view.dart';
import '../../screens/payments/transaction_history_screen.dart';
import '../../screens/refunds/refund_request_screen.dart';
import '../../screens/payments/my_payments_screen.dart';
import '../../screens/refunds/my_refunds_screen.dart';
import '../../screens/analytics/approval_likelihood_screen.dart';

class ApplicationsTab extends StatelessWidget {
  final String token;
  final String userEmail;

  const ApplicationsTab({
    super.key,
    required this.token,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Applications'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── Active Applications ──────────────────────────────────────
          _buildSectionHeader('Active Applications'),
          const SizedBox(height: 10),
          _buildTrackingCard(
            title: 'Small Business Registration',
            referenceId: 'APP-2026-8841',
            status: 'In Officer Review',
            statusColor: AppColors.warning,
            date: 'Submitted Aug 2, 2026',
          ),
          const SizedBox(height: 10),
          _buildTrackingCard(
            title: 'Driving Licence Replacement',
            referenceId: 'APP-2026-7102',
            status: 'Approved',
            statusColor: AppColors.success,
            date: 'Completed Jul 15, 2026',
          ),
          const SizedBox(height: 28),

          // ── Payments ─────────────────────────────────────────────────
          _buildSectionHeader('Payments'),
          const SizedBox(height: 10),
          _buildActionTile(
            context: context,
            icon: CupertinoIcons.creditcard,
            iconColor: AppColors.primary,
            title: 'Payment Details',
            subtitle: 'Pay service fees for your application',
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => PaymentScreen(
                    token: token,
                    userEmail: userEmail,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildActionTile(
            context: context,
            icon: CupertinoIcons.calendar,
            iconColor: AppColors.warning,
            title: 'Installment Schedule',
            subtitle: 'View installment breakdown & due dates',
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => InstallmentPlanView(
                    token: token,
                  ),
                ),
              );
            },
          ),
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
                  builder: (_) => TransactionHistoryScreen(
                    token: token,
                    userEmail: userEmail,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildActionTile(
            context: context,
            icon: CupertinoIcons.money_dollar_circle,
            iconColor: AppColors.primary,
            title: 'My Payments',
            subtitle: 'View all your payment transactions',
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => MyPaymentsScreen(
                    token: token,
                    userEmail: userEmail,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // ── Refunds ──────────────────────────────────────────────────
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
                  builder: (_) => RefundRequestScreen(
                    token: token,
                  ),
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
                  builder: (_) => MyRefundsScreen(token: token),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // ── Analytics ────────────────────────────────────────────────
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
                  builder: (_) =>
                      ApprovalLikelihoodScreen(token: token),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
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

  Widget _buildTrackingCard({
    required String title,
    required String referenceId,
    required String status,
    required Color statusColor,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                referenceId,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryLabel),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.dark),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: const TextStyle(
                fontSize: 13, color: AppColors.secondaryLabel),
          ),
        ],
      ),
    );
  }
}