import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';
import '../models/refund.dart';

class RefundTrackerWidget extends StatelessWidget {
  final RefundStatus status;
  final String? decisionNote;

  const RefundTrackerWidget({
    super.key,
    required this.status,
    this.decisionNote,
  });

  @override
  Widget build(BuildContext context) {
    final isRejected = status == RefundStatus.rejected;
    final isFailed = status == RefundStatus.failed;

    final steps = [
      _StepInfo(
        title: 'Pending',
        subtitle: 'Submitted',
        index: 0,
      ),
      _StepInfo(
        title: isRejected ? 'Rejected' : 'Approved',
        subtitle: isRejected ? 'Declined' : 'Reviewed',
        index: 1,
        isTerminalFailure: isRejected,
      ),
      _StepInfo(
        title: 'Processing',
        subtitle: 'Transferring',
        index: 2,
      ),
      _StepInfo(
        title: isFailed ? 'Failed' : 'Completed',
        subtitle: isFailed ? 'Payout Failed' : 'Refund Sent',
        index: 3,
        isTerminalFailure: isFailed,
      ),
    ];

    final currentStepIndex = _getCurrentStepIndex(status);

    return Container(
      padding: const EdgeInsets.all(20),
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
              const Text(
                'Refund Status Tracker',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              if (isRejected || isFailed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isRejected ? 'Rejected' : 'Failed',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Horizontal Stepper Bar
          Row(
            children: List.generate(steps.length, (idx) {
              final step = steps[idx];
              final isLast = idx == steps.length - 1;

              final isCompleted = _isStepCompleted(idx, currentStepIndex, status);
              final isActive = _isStepActive(idx, currentStepIndex, status);
              final isFailedStep = step.isTerminalFailure && (isActive || isCompleted);

              return Expanded(
                child: Row(
                  children: [
                    // Step Circle
                    Column(
                      children: [
                        _buildStepNode(
                          index: idx + 1,
                          isCompleted: isCompleted,
                          isActive: isActive,
                          isFailedStep: isFailedStep,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: (isActive || isCompleted)
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isFailedStep
                                ? AppColors.danger
                                : isCompleted
                                    ? AppColors.success
                                    : isActive
                                        ? AppColors.primary
                                        : AppColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),

                    // Connecting Line (if not last)
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 22, left: 4, right: 4),
                          decoration: BoxDecoration(
                            color: _getLineColor(idx, currentStepIndex, status),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          if (decisionNote != null && decisionNote!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRejected || isFailed
                    ? AppColors.danger.withValues(alpha: 0.08)
                    : AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isRejected || isFailed
                      ? AppColors.danger.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Decision Note:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isRejected || isFailed ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    decisionNote!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getCurrentStepIndex(RefundStatus status) {
    switch (status) {
      case RefundStatus.pending:
        return 0;
      case RefundStatus.approved:
        return 1;
      case RefundStatus.rejected:
        return 1;
      case RefundStatus.processing:
        return 2;
      case RefundStatus.completed:
        return 3;
      case RefundStatus.failed:
        return 3;
    }
  }

  bool _isStepCompleted(int stepIdx, int currentIdx, RefundStatus status) {
    if (status == RefundStatus.rejected) {
      return stepIdx < 1;
    }
    if (status == RefundStatus.failed) {
      return stepIdx < 3;
    }
    return stepIdx < currentIdx;
  }

  bool _isStepActive(int stepIdx, int currentIdx, RefundStatus status) {
    return stepIdx == currentIdx;
  }

  Color _getLineColor(int stepIdx, int currentIdx, RefundStatus status) {
    if (status == RefundStatus.rejected && stepIdx >= 1) {
      return AppColors.divider;
    }
    if (stepIdx < currentIdx) {
      return AppColors.success;
    }
    return AppColors.divider;
  }

  Widget _buildStepNode({
    required int index,
    required bool isCompleted,
    required bool isActive,
    required bool isFailedStep,
  }) {
    if (isFailedStep) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.danger,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.xmark,
          color: Colors.white,
          size: 18,
        ),
      );
    }

    if (isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.checkmark,
          color: Colors.white,
          size: 18,
        ),
      );
    }

    if (isActive) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2.5),
        ),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Center(
        child: Text(
          '$index',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryLabel,
          ),
        ),
      ),
    );
  }
}

class _StepInfo {
  final String title;
  final String subtitle;
  final int index;
  final bool isTerminalFailure;

  _StepInfo({
    required this.title,
    required this.subtitle,
    required this.index,
    this.isTerminalFailure = false,
  });
}
