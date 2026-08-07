import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service Catalog'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildServiceItem(
            title: 'Small Business Registration',
            category: 'Commerce & Enterprise',
            fee: 'LKR 5,000',
            icon: CupertinoIcons.briefcase,
          ),
          const SizedBox(height: 12),
          _buildServiceItem(
            title: 'Driving Licence Renewal',
            category: 'Department of Motor Traffic',
            fee: 'LKR 3,500',
            icon: CupertinoIcons.car_detailed,
          ),
          const SizedBox(height: 12),
          _buildServiceItem(
            title: 'Passport Application & Renewal',
            category: 'Immigration & Emigration',
            fee: 'LKR 10,000',
            icon: CupertinoIcons.doc_on_clipboard,
          ),
          const SizedBox(height: 12),
          _buildServiceItem(
            title: 'National Identity Card Replacement',
            category: 'Department for Registration of Persons',
            fee: 'LKR 1,500',
            icon: CupertinoIcons.person_crop_circle_fill,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required String title,
    required String category,
    required String fee,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fee,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: AppColors.secondaryLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}