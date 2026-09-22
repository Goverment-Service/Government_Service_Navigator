import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final String? token;
  final String? userEmail;

  const TransactionHistoryScreen({
    super.key,
    this.token,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppColors.cardBg,
      ),
      body: const Center(
        child: Text('Transaction History Screen Placeholder'),
      ),
    );
  }
}
