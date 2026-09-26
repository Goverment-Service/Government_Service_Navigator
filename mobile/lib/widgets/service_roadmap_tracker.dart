import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

class ServiceRoadmapTracker extends StatelessWidget {
  final int currentStage;
  final int maxStages;
  final String stageStatus;
  final VoidCallback? onActionTap;
  final List<String>? stageDepartments;
  final String? currentDepartment;
  final VoidCallback? onFillStageFormTap;
  final String? fillStageFormButtonText;

  const ServiceRoadmapTracker({
    super.key,
    required this.currentStage,
    required this.maxStages,
    required this.stageStatus,
    this.onActionTap,
    this.stageDepartments,
    this.currentDepartment,
    this.onFillStageFormTap,
    this.fillStageFormButtonText,
  });

  List<String> get _defaultStageNames {
    if (stageDepartments != null && stageDepartments!.isNotEmpty) {
      return List.generate(maxStages, (i) {
        if (i < stageDepartments!.length) {
          final dept = stageDepartments![i];
          return 'Stage ${i + 1}: $dept Review';
        }
        return 'Stage ${i + 1}: Department Review';
      });
    }
    if (maxStages == 3) {
      return [
        'Document Review',
        'Fee & Payment',
        'Fulfillment & Collection',
      ];
    } else if (maxStages == 2) {
      return [
        'Initial Verification',
        'Departmental Approval',
      ];
    }
    return [
      'Document Review & Verification',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stages = _defaultStageNames;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.map_fill, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Service Progress Roadmap',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Stage $currentStage of $maxStages',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < stages.length; i++) ...[
            _buildStageItem(
              stageNumber: i + 1,
              title: stages[i],
              isPassed: (i + 1) < currentStage || (stageStatus == 'Completed' && (i + 1) <= maxStages),
              isCurrent: (i + 1) == currentStage && stageStatus != 'Completed',
              isLast: i == stages.length - 1,
            ),
          ],
          if (stageStatus == 'AwaitingFeePayment' && onActionTap != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                onPressed: onActionTap,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.creditcard_fill, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Pay Statutory Fee Now',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    SizedBox(width: 6),
                    Icon(CupertinoIcons.arrow_right, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
          if (stageStatus == 'StageApproved' && onFillStageFormTap != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
                onPressed: onFillStageFormTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.doc_text_fill, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      fillStageFormButtonText ?? 'Fill Stage $currentStage Form Now',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Icon(CupertinoIcons.arrow_right, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStageItem({
    required int stageNumber,
    required String title,
    required bool isPassed,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color iconBg;
    IconData icon;
    Color iconColor;

    if (isPassed) {
      iconBg = AppColors.success.withValues(alpha: 0.15);
      icon = CupertinoIcons.checkmark_alt;
      iconColor = AppColors.success;
    } else if (isCurrent) {
      iconBg = AppColors.primary.withValues(alpha: 0.15);
      icon = CupertinoIcons.circle_fill;
      iconColor = AppColors.primary;
    } else {
      iconBg = Colors.grey.withValues(alpha: 0.15);
      icon = CupertinoIcons.lock_fill;
      iconColor = Colors.grey;
    }

    final isTappable = isCurrent && onActionTap != null;

    final String? assignedDept = (stageDepartments != null && stageNumber - 1 < stageDepartments!.length)
        ? stageDepartments![stageNumber - 1]
        : null;

    final String statusSubtitle;
    if (isPassed) {
      statusSubtitle = assignedDept != null
          ? 'Approved by $assignedDept Officer'
          : 'Approved by Verification Officer';
    } else if (isCurrent) {
      if (stageStatus == 'AwaitingFeePayment') {
        statusSubtitle = 'Active / In-Progress • Tap to complete payment';
      } else if (stageStatus == 'StageApproved') {
        statusSubtitle = assignedDept != null
            ? 'Unlocked! Ready for $assignedDept form submission'
            : 'Unlocked! Ready for next stage submission';
      } else {
        statusSubtitle = assignedDept != null
            ? 'Active • Under review by $assignedDept'
            : 'Active / In-Progress • Under official verification';
      }
    } else {
      statusSubtitle = assignedDept != null
          ? 'Locked until prior stage completed • $assignedDept'
          : (stageNumber == 3
              ? 'Locked until payment verified'
              : 'Locked until prior stage completed');
    }

    return InkWell(
      onTap: isTappable ? onActionTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 26,
                    color: isPassed ? AppColors.success : Colors.grey.withValues(alpha: 0.25),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                          color: isPassed
                              ? AppColors.dark
                              : isCurrent
                                  ? AppColors.primary
                                  : AppColors.secondaryLabel,
                        ),
                      ),
                      if (isTappable) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Action Ready',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.warning),
                          ),
                        ),
                        const Spacer(),
                        const Icon(CupertinoIcons.chevron_right, size: 13, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusSubtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrent && stageStatus == 'AwaitingFeePayment'
                          ? AppColors.warning
                          : isPassed
                              ? AppColors.success
                              : AppColors.secondaryLabel,
                      fontWeight: isCurrent && stageStatus == 'AwaitingFeePayment'
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
