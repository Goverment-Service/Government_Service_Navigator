import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../services/refund_service.dart';
import 'refund_detail_screen.dart';

class RefundRequestScreen extends StatefulWidget {
  final String? token;
  final String? paymentId;
  final double? amount;

  const RefundRequestScreen({
    super.key,
    this.token,
    this.paymentId,
    this.amount,
  });

  @override
  State<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends State<RefundRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _paymentIdController;
  late final TextEditingController _amountController;
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

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

  String get _effectivePaymentId {
    if (widget.paymentId != null && widget.paymentId!.isNotEmpty) {
      return widget.paymentId!;
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic> && routeArgs.containsKey('paymentId')) {
      return routeArgs['paymentId']?.toString() ?? '';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _paymentIdController = TextEditingController(text: widget.paymentId ?? '');
    _amountController = TextEditingController(
      text: widget.amount != null && widget.amount! > 0
          ? widget.amount!.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_paymentIdController.text.isEmpty && _effectivePaymentId.isNotEmpty) {
      _paymentIdController.text = _effectivePaymentId;
    }
  }

  @override
  void dispose() {
    _paymentIdController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _mapErrorMessage(String rawError) {
    final clean = rawError.replaceAll('Exception: ', '').trim();
    final lower = clean.toLowerCase();

    if (lower.contains('not found')) {
      return "We couldn't find that payment";
    }
    if (lower.contains('only paid payments are eligible')) {
      return "This payment isn't eligible for a refund yet";
    }
    if (lower.contains('refund window has expired') || lower.contains('expired')) {
      return "Refunds must be requested within 3 days of payment";
    }
    if (lower.contains('already exists') || lower.contains('active refund request')) {
      return "You already have a refund request in progress for this payment";
    }
    return clean;
  }

  Future<void> _onSubmitPressed() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = RefundService(_effectiveToken);
      final pId = _paymentIdController.text.trim();
      final amt = double.parse(_amountController.text.trim());
      final rsn = _reasonController.text.trim();

      final refundReq = await service.submitRefund(
        paymentId: pId,
        refundAmount: amt,
        reason: rsn,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => RefundDetailScreen(
            token: _effectiveToken,
            refundId: refundReq.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _mapErrorMessage(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Request Refund'),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Information card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.info_circle_fill, color: AppColors.primary, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Submit a refund request for a completed payment. Requests are reviewed within 3 days.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.dark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment ID Input
                _buildLabel('Payment ID'),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _paymentIdController,
                  hint: 'Enter Payment ID (e.g. PAY-1001)',
                  icon: CupertinoIcons.creditcard_fill,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Payment ID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Refund Amount Input
                _buildLabel('Refund Amount (LKR)'),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _amountController,
                  hint: '0.00',
                  icon: CupertinoIcons.money_dollar_circle_fill,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Refund amount is required';
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) {
                      return 'Enter a valid refund amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Reason Text Field
                _buildLabel('Reason for Refund'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider, width: 0.8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextFormField(
                      controller: _reasonController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 16, color: AppColors.dark),
                      decoration: const InputDecoration(
                        hintText: 'Please state the detailed reason for your refund request...',
                        hintStyle: TextStyle(color: AppColors.secondaryLabel, fontSize: 15),
                        border: InputBorder.none,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 10) {
                          return 'Reason must be at least 10 characters long';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.danger, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(14),
                    onPressed: _isLoading ? null : _onSubmitPressed,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: Colors.white, radius: 11)
                        : const Text(
                            'Submit Refund Request',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String labelText) {
    return Text(
      labelText,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLabel,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16, color: AppColors.dark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.secondaryLabel, fontSize: 15),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            border: InputBorder.none,
          ),
          validator: validator,
        ),
      ),
    );
  }
}

