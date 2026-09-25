import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/agent_providers.dart';
import '../../models/analytics.dart';

class ApprovalLikelihoodScreen extends ConsumerStatefulWidget {
  final String? prefillServiceProcedureId;

  const ApprovalLikelihoodScreen({
    super.key,
    this.prefillServiceProcedureId,
  });

  @override
  ConsumerState<ApprovalLikelihoodScreen> createState() =>
      _ApprovalLikelihoodScreenState();
}

class _ApprovalLikelihoodScreenState
    extends ConsumerState<ApprovalLikelihoodScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _idController;
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _animController;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(
        text: widget.prefillServiceProcedureId ?? '');
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnim =
        Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (!_formKey.currentState!.validate()) return;
    _animController.reset();

    await ref
        .read(approvalLikelihoodControllerProvider.notifier)
        .check(_idController.text.trim());
    if (mounted && ref.read(approvalLikelihoodControllerProvider).hasValue) {
      _animController.forward();
    }
  }

  Color _likelihoodColor(int percent) {
    if (percent >= 70) return AppColors.success;
    if (percent >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final check = ref.watch(approvalLikelihoodControllerProvider);
    final isLoading = check.isLoading;
    final errorMessage = check.hasError ? check.error.toString() : null;
    final result = check.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Approval Likelihood'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_left,
              color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explainer card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(CupertinoIcons.chart_bar_fill,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AI Approval Predictor',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter a service procedure ID to see how likely your application is to be approved based on historical data.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SERVICE PROCEDURE ID',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryLabel,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.divider, width: 0.8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: TextFormField(
                          controller: _idController,
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.dark),
                          decoration: InputDecoration(
                            hintText: 'e.g. SP-1042',
                            hintStyle: const TextStyle(
                                color: AppColors.secondaryLabel, fontSize: 16),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            prefixIcon: const Icon(CupertinoIcons.doc_text,
                                color: AppColors.primary, size: 20),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(14),
                        onPressed: isLoading ? null : _check,
                        child: isLoading
                            ? const CupertinoActivityIndicator(
                                color: Colors.white, radius: 11)
                            : const Text(
                                'Check Likelihood',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              if (errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_circle,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errorMessage,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              if (result != null) ...[
                const SizedBox(height: 28),
                _buildResultCard(result),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(ApprovalLikelihood result) {
    final color = _likelihoodColor(result.approvalLikelihoodPercent);
    final fraction = result.approvalLikelihoodPercent / 100.0;

    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (context, _) {
        final animatedFraction = fraction * _progressAnim.value;
        final animatedPercent =
            (result.approvalLikelihoodPercent * _progressAnim.value).round();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider, width: 0.8),
          ),
          child: Column(
            children: [
              // Circular indicator
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: animatedFraction,
                        strokeWidth: 10,
                        backgroundColor:
                            color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$animatedPercent%',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: -1),
                        ),
                        const Text(
                          'likelihood',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                result.approvalLikelihoodPercent >= 70
                    ? 'High likelihood of approval'
                    : result.approvalLikelihoodPercent >= 40
                        ? 'Moderate likelihood — review criteria'
                        : 'Low likelihood — check requirements',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on ${result.sampleSize} historical applications',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.secondaryLabel),
              ),
              const SizedBox(height: 20),

              // Bar indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: animatedFraction,
                  minHeight: 10,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
