import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../services/session_store.dart';
import '../../screens/login_page.dart';
import '../../screens/payment/pay_fee_screen.dart';
import '../../screens/payment/payment_history_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _signOut(BuildContext context) async {
    await SessionStore.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider, width: 0.8),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    CupertinoIcons.person_fill,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Citizen Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'National ID Verified',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildProfileOption(
            icon: CupertinoIcons.money_dollar_circle,
            title: 'Pay a Fee',
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const PayFeeScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _buildProfileOption(
            icon: CupertinoIcons.doc_text,
            title: 'My Payments',
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const PaymentHistoryScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _buildProfileOption(
            icon: CupertinoIcons.doc_person,
            title: 'My Digital Documents',
          ),
          const SizedBox(height: 8),
          _buildProfileOption(
            icon: CupertinoIcons.bell,
            title: 'Notification Preferences',
          ),
          const SizedBox(height: 8),
          _buildProfileOption(
            icon: CupertinoIcons.lock_shield,
            title: 'Security & Verification',
          ),
          const SizedBox(height: 8),
          _buildProfileOption(
            icon: CupertinoIcons.arrow_right_square,
            title: 'Sign Out',
            isDanger: true,
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    final color = isDanger ? AppColors.danger : AppColors.dark;
    final iconColor = isDanger ? AppColors.danger : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: color),
        ),
        trailing: const Icon(
          CupertinoIcons.chevron_right,
          size: 16,
          color: AppColors.secondaryLabel,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }
}