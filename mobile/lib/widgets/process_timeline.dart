import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/application.dart';

class TimelineStep {
  final String label;
  final DateTime? timestamp;
  final bool complete;
  final Color color;

  TimelineStep({required this.label, this.timestamp, required this.complete, required this.color});
}

String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

List<TimelineStep> _stepsForApplication(ServiceApplication app) {
  final decided = app.decisionAt != null;
  final decisionColor = switch (app.status) {
    'Approved' => AppColors.success,
    'Rejected' => AppColors.danger,
    'Revised' => AppColors.warning,
    _ => AppColors.secondaryLabel,
  };

  return [
    TimelineStep(label: 'Application Submitted', timestamp: app.submittedAt, complete: true, color: AppColors.primary),
    TimelineStep(
      label: decided ? 'Reviewed by Officer' : 'Pending Review',
      timestamp: null,
      complete: decided || app.status == 'Pending',
      color: decided ? AppColors.primary : AppColors.warning,
    ),
    TimelineStep(
      label: decided ? app.status : 'Awaiting Decision',
      timestamp: app.decisionAt,
      complete: decided,
      color: decisionColor,
    ),
  ];
}

/// A simple vertical stepper showing an application's progress: Submitted ->
/// Pending Review -> Decision, built entirely from data that already exists
/// on the application (submittedAt/status/decisionAt) - no separate backend
/// workflow state required.
///
/// [formName] is the actual Template form name/identifier the officer set
/// (e.g. "Tesst") - distinct from the Service Catalog's service name shown
/// elsewhere - so falls back to [app.serviceName] when the service has no
/// template (or it hasn't loaded yet).
Widget processTimeline(ServiceApplication app, {String? formName}) {
  final steps = _stepsForApplication(app);
  final title = (formName?.isNotEmpty ?? false) ? formName! : app.serviceName;
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
        const Text('Process Timeline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 13)),
        const SizedBox(height: 12),
        for (var i = 0; i < steps.length; i++) _timelineRow(steps[i], isLast: i == steps.length - 1),
      ],
    ),
  );
}

Widget _timelineRow(TimelineStep step, {required bool isLast}) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.complete ? step.color : Colors.white,
                border: Border.all(color: step.color, width: 2),
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(width: 2, color: step.complete ? step.color.withValues(alpha: 0.4) : AppColors.divider),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontWeight: step.complete ? FontWeight.w600 : FontWeight.w400,
                    color: step.complete ? AppColors.dark : AppColors.secondaryLabel,
                  ),
                ),
                if (step.timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(_formatDate(step.timestamp!), style: const TextStyle(fontSize: 12, color: AppColors.secondaryLabel)),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
