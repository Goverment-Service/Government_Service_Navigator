import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../models/payment.dart';
import 'payment_history_screen.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final Payment payment;
  const PaymentReceiptScreen({super.key, required this.payment});

  bool get _isStripe => payment.method == 'Stripe';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Icon(
                _isStripe ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.clock_fill,
                color: _isStripe ? AppColors.success : AppColors.primary,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _isStripe ? 'Payment Successful' : 'Payment Submitted',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _isStripe
                    ? 'Your card payment was confirmed. A receipt has been emailed to you.'
                    : 'Your slip was received. Your payment is Pending verification by a Finance Officer, and you\'ll get an email once it\'s confirmed.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.secondaryLabel),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Reference', payment.transactionReference),
                    _row('Service', payment.serviceName),
                    _row('Amount', '${payment.currency} ${payment.amount.toStringAsFixed(2)}'),
                    _row('Status', payment.status),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    CupertinoPageRoute(builder: (_) => const PaymentHistoryScreen()),
                    (route) => route.isFirst,
                  ),
                  child: const Text('View My Payments'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.secondaryLabel)),
            Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
