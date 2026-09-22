import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class RefundRequestScreen extends StatelessWidget {
  final String? token;
  final String? paymentId;

  const RefundRequestScreen({
    super.key,
    this.token,
    this.paymentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Refund Request'),
        backgroundColor: AppColors.cardBg,
      ),
      body: const Center(
        child: Text('Refund Request Screen Placeholder'),
      ),
    );
  }
}
