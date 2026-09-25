import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../screens/login_page.dart';
import '../../theme/app_colors.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: Colors.transparent,
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
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    CupertinoIcons.person_fill,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.fullName ?? 'Citizen Account',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      if (session.email.isNotEmpty)
                        Text(
                          session.email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.secondaryLabel),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
            onTap: () {
              ref.read(authControllerProvider.notifier).signOut();
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                CupertinoPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}