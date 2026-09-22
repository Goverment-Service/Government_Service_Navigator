import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../services/payment_service.dart';
import 'checkout_webview_screen.dart';

class PaymentScreen extends StatefulWidget {
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
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String? _resultMessage;
  bool _isSuccess = false;

  String? _paymentId;
  String? _checkoutUrl;
  String? _paymentStatus;
  bool _isPaid = false;



  String get _effectiveToken {
    if (widget.token != null && widget.token!.isNotEmpty) {
      return widget.token!;
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic> && routeArgs.containsKey('token')) {
      return routeArgs['token']?.toString() ?? '';
    }
    return '';
  }

  String get _effectiveUserEmail {
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      return widget.userEmail!;
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic> && routeArgs.containsKey('userEmail')) {
      return routeArgs['userEmail']?.toString() ?? 'citizen@example.com';
    }
    return 'citizen@example.com';
  }

  String get _effectiveAppId {
    if (widget.applicationId != null && widget.applicationId!.isNotEmpty) {
      return widget.applicationId!;
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic> && routeArgs.containsKey('applicationId')) {
      return routeArgs['applicationId']?.toString() ?? 'APP-2026-8841';
    }
    return 'APP-2026-8841';
  }

  double get _effectiveAmount {
    if (widget.amount != null && widget.amount! > 0) {
      return widget.amount!;
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic> && routeArgs.containsKey('amount')) {
      final val = routeArgs['amount'];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 2500.0;
    }
    return 2500.00;
  }

  Future<void> _onPayNowPressed() async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
      _paymentId = null;
      _checkoutUrl = null;
      _paymentStatus = null;
      _isPaid = false;
      _isSuccess = false;
    });

    try {
      final service = PaymentService(_effectiveToken);
      final response = await service.checkout(
        applicationId: _effectiveAppId,
        amount: _effectiveAmount,
        userEmail: _effectiveUserEmail,
      );

      if (!mounted) return;
      setState(() {
        _paymentId = response.paymentId;
        _checkoutUrl = response.checkoutUrl;
      });


      if (response.checkoutUrl.isNotEmpty) {
        final result = await Navigator.of(context).push<bool>(
          CupertinoPageRoute(
            builder: (_) => CheckoutWebViewScreen(checkoutUrl: response.checkoutUrl),
          ),
        );

        if (!mounted) return;
        if (result == true && _paymentId != null) {
          await _confirmPayment(_paymentId!);
        } else if (result == false) {
          setState(() {
            _isLoading = false;
            _isSuccess = false;
            _resultMessage = 'Payment checkout was cancelled or failed.';
          });
        } else {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
            _resultMessage = 'Checkout session created (ID: $_paymentId). Complete payment or check status.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _resultMessage = 'Checkout session created (ID: ${response.paymentId}).';
        });
      }
    } catch (e) {

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _confirmPayment(String paymentId) async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      final service = PaymentService(_effectiveToken);
      final payment = await service.confirmPayment(paymentId);

      if (!mounted) return;
      final statusStr = payment.status ?? 'Pending';
      final isPaid = statusStr.toLowerCase() == 'paid' || statusStr.toLowerCase() == 'completed';

      setState(() {
        _isLoading = false;
        _paymentStatus = statusStr;
        _isPaid = isPaid;
        _isSuccess = isPaid;
        if (isPaid) {
          _resultMessage = 'Payment successful';
        } else {
          _resultMessage = 'Payment status: $statusStr';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appId = _effectiveAppId;
    final feeAmount = _effectiveAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_left, color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Calculated Service Fee',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'LKR Currency',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LKR ${feeAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Application ID: $appId',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Details Group Card
              const Text(
                'Payment Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider, width: 0.8),
                ),
                child: Column(
                  children: [
                    _buildRow('Application ID', appId),
                    const Divider(height: 1, color: AppColors.divider, indent: 16),
                    _buildRow('Fee Amount', 'LKR ${feeAmount.toStringAsFixed(2)}'),
                    const Divider(height: 1, color: AppColors.divider, indent: 16),
                    _buildRow('Payer Email', _effectiveUserEmail),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Pay Now Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(14),
                  onPressed: _isLoading ? null : _onPayNowPressed,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white, radius: 11)
                      : const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Space for loading / result state display below button
              if (_isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CupertinoActivityIndicator(radius: 14),
                  ),
                ),
              ] else if (_isPaid) ...[
                // Paid Success State Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: AppColors.success,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Payment successful',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Status: ${_paymentStatus ?? "Paid"} • ID: ${_paymentId ?? ""}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_resultMessage != null || _paymentStatus != null) ...[
                // Non-paid / Status result card with "Check Again" button if not paid
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isSuccess
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isSuccess
                                ? CupertinoIcons.info_circle_fill
                                : CupertinoIcons.exclamationmark_circle_fill,
                            color: _isSuccess ? AppColors.primary : AppColors.danger,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _resultMessage ?? 'Status: ${_paymentStatus ?? "Pending"}',
                              style: TextStyle(
                                color: _isSuccess ? AppColors.dark : AppColors.danger,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_checkoutUrl != null && _checkoutUrl!.isNotEmpty && !_isPaid) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            borderRadius: BorderRadius.circular(10),
                            onPressed: () async {
                              final result = await Navigator.of(context).push<bool>(
                                CupertinoPageRoute(
                                  builder: (_) => CheckoutWebViewScreen(checkoutUrl: _checkoutUrl!),
                                ),
                              );
                              if (result == true && _paymentId != null) {
                                await _confirmPayment(_paymentId!);
                              }
                            },
                            child: const Text(
                              'Open Checkout Gateway',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_paymentId != null && !_isPaid) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            color: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            borderRadius: BorderRadius.circular(10),
                            onPressed: () => _confirmPayment(_paymentId!),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.refresh, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Check Again',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.secondaryLabel,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}


