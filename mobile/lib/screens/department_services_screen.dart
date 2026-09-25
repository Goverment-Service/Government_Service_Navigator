import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import 'procedure_detail_screen.dart';

class DepartmentServicesScreen extends StatelessWidget {
  final String department;
  final List<Map<String, dynamic>> services;
  final String token;

  const DepartmentServicesScreen({
    super.key,
    required this.department,
    required this.services,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(department),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          final fees = service['feeSchedules'] as List? ?? [];
          final feeString = fees.isNotEmpty ? 'LKR ${fees[0]['amount']}' : 'Free';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => ProcedureDetailScreen(
                      serviceId: service['id'],
                      token: token,
                    ),
                  ),
                );
              },
              child: _buildServiceItem(
                title: service['name'] ?? 'Untitled Service',
                subtitle: service['serviceId'] ?? department,
                fee: feeString,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceItem({
    required String title,
    required String subtitle,
    required String fee,
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
            child: const Icon(CupertinoIcons.doc_text, color: AppColors.primary, size: 24),
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
                  subtitle,
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
