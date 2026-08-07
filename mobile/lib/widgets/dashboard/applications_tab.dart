import 'package:flutter/material.dart';
//import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';

class ApplicationsTab extends StatelessWidget {
  const ApplicationsTab({super.key});

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
          _buildTrackingCard(
            title: 'Small Business Registration',
            referenceId: 'APP-2026-8841',
            status: 'In Officer Review',
            statusColor: AppColors.warning,
            date: 'Submitted Aug 2, 2026',
          ),
          const SizedBox(height: 12),
          _buildTrackingCard(
            title: 'Driving Licence Replacement',
            referenceId: 'APP-2026-7102',
            status: 'Approved',
            statusColor: AppColors.success,
            date: 'Completed Jul 15, 2026',
          ),
        ],
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
                  color: AppColors.secondaryLabel,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
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
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}