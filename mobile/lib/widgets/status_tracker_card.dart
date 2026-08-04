import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusTrackerCard extends StatelessWidget {
  final String applicationName;
  final String status;
  final String date;
  final IconData icon;

  const StatusTrackerCard({
    super.key,
    required this.applicationName,
    required this.status,
    required this.date,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status color based on text
    Color statusColor;
    if (status.toLowerCase().contains('approved')) {
      statusColor = Colors.green;
    } else if (status.toLowerCase().contains('pending') ||
        status.toLowerCase().contains('review')) {
      statusColor = Colors.orange;
    } else if (status.toLowerCase().contains('rejected') ||
        status.toLowerCase().contains('action')) {
      statusColor = Colors.red;
    } else {
      statusColor = AppTheme.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue),
        ),
        title: Text(
          applicationName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(date, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
