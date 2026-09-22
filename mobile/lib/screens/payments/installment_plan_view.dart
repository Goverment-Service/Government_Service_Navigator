import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class InstallmentPlanView extends StatelessWidget {
  final String? token;
  final String? planId;
  final String? paymentId;

  const InstallmentPlanView({
    super.key,
    this.token,
    this.planId,
    this.paymentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Installment Plan View'),
        backgroundColor: AppColors.cardBg,
      ),
      body: const Center(
        child: Text('Installment Plan View Placeholder'),
      ),
    );
  }
}
