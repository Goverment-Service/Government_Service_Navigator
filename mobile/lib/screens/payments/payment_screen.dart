import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PaymentScreen extends StatelessWidget {
  final String? token;
  final String? userEmail;
  final String? applicationId;
  final double? amount;

  const PaymentScreen({
    super.key,
    this.token,
    this.userEmail,
    this.applicationId,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Make Payment'),
        backgroundColor: AppColors.cardBg,
      ),
      body: const Center(
        child: Text('Payment Screen Placeholder'),
      ),
    );
  }
}
