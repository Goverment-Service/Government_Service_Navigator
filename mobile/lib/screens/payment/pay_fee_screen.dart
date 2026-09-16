import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../theme/app_colors.dart';
import '../../services/payment_service.dart';
import '../../models/payment.dart';
import 'payment_receipt_screen.dart';

class PayFeeScreen extends StatefulWidget {
  const PayFeeScreen({super.key});

  @override
  State<PayFeeScreen> createState() => _PayFeeScreenState();
}

enum _PayMethod { bankTransfer, stripe }

class _PayFeeScreenState extends State<PayFeeScreen> {
  final _paymentService = PaymentService();
  final _formKey = GlobalKey<FormState>();

  final _serviceNameController = TextEditingController();
  final _applicationIdController = TextEditingController();
  final _amountController = TextEditingController();

  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  File? _slip;

  _PayMethod _method = _PayMethod.bankTransfer;
  BankDetails? _bankDetails;
  bool _stripeConfigured = false;
  bool _loadingConfig = true;
  bool _submitting = false;
  String? _error;

  final _cardController = CardFormEditController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _applicationIdController.dispose();
    _amountController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _accountNumberController.dispose();
    _referenceNumberController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final bank = await _paymentService.fetchBankDetails();
      final stripeConfig = await _paymentService.fetchStripeConfig();
      final configured = stripeConfig['configured'] == true;
      final publishableKey = stripeConfig['publishableKey'] as String? ?? '';
      if (configured && publishableKey.isNotEmpty) {
        Stripe.publishableKey = publishableKey;
        await Stripe.instance.applySettings();
      }
      if (!mounted) return;
      setState(() {
        _bankDetails = bank;
        _stripeConfigured = configured && publishableKey.isNotEmpty;
        _loadingConfig = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingConfig = false;
        _error = 'Could not load payment configuration.';
      });
    }
  }

  Future<void> _pickSlip(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => _slip = File(picked.path));
    }
  }

  bool get _detailsValid =>
      _serviceNameController.text.trim().isNotEmpty &&
      (double.tryParse(_amountController.text.trim()) ?? 0) > 0;

  Future<void> _submitBankTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_slip == null) {
      setState(() => _error = 'Please attach your payment slip.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final payment = await _paymentService.submitBankTransferPayment(
        applicationId: _applicationIdController.text.trim(),
        serviceName: _serviceNameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        bankName: _bankNameController.text.trim(),
        branchName: _branchNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        referenceNumber: _referenceNumberController.text.trim(),
        paymentDate: _paymentDate,
        slip: _slip!,
      );
      _goToReceipt(payment);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _payWithCard() async {
    if (!_detailsValid) {
      setState(() => _error = 'Enter a service name and amount first.');
      return;
    }
    if (!_cardController.details.complete) {
      setState(() => _error = 'Enter your complete card details.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final intent = await _paymentService.createStripeIntent(
        applicationId: _applicationIdController.text.trim(),
        serviceName: _serviceNameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
      );
      final clientSecret = intent['clientSecret'] as String;
      final paymentId = intent['paymentId'] as int;

      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(paymentMethodData: PaymentMethodData()),
      );

      final payment = await _paymentService.syncStripePayment(paymentId);
      _goToReceipt(payment);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goToReceipt(Payment payment) {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (_) => PaymentReceiptScreen(payment: payment)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pay a Service Fee'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: _loadingConfig
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionCard([
                        _textField(_serviceNameController, 'Service Name', hint: 'e.g. Birth Certificate Application'),
                        const SizedBox(height: 12),
                        _textField(_applicationIdController, 'Application ID (optional)'),
                        const SizedBox(height: 12),
                        _textField(_amountController, 'Amount', keyboardType: TextInputType.number),
                      ]),
                      const SizedBox(height: 16),
                      CupertinoSlidingSegmentedControl<_PayMethod>(
                        groupValue: _method,
                        children: {
                          _PayMethod.bankTransfer: _segmentLabel('Bank Transfer'),
                          if (_stripeConfigured) _PayMethod.stripe: _segmentLabel('Card (Stripe)'),
                        },
                        onValueChanged: (v) {
                          if (v != null) setState(() => _method = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_error != null) _errorBanner(_error!),
                      if (_error != null) const SizedBox(height: 12),
                      if (_method == _PayMethod.bankTransfer) _buildBankTransferForm(),
                      if (_method == _PayMethod.stripe && _stripeConfigured) _buildStripeForm(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _segmentLabel(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );

  Widget _buildBankTransferForm() {
    return _sectionCard([
      if (_bankDetails != null) ...[
        const Text('Please make your payment to:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(_bankDetails!.accountName),
        Text('${_bankDetails!.bankName} · ${_bankDetails!.branchName}'),
        Text('Account No: ${_bankDetails!.accountNumber}'),
        const SizedBox(height: 16),
      ],
      _textField(_bankNameController, 'Your Bank Name'),
      const SizedBox(height: 12),
      _textField(_branchNameController, 'Branch'),
      const SizedBox(height: 12),
      _textField(_accountNumberController, 'Your Account Number'),
      const SizedBox(height: 12),
      _textField(_referenceNumberController, 'Transaction / Slip Reference Number'),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _paymentDate,
            firstDate: DateTime.now().subtract(const Duration(days: 30)),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => _paymentDate = picked);
        },
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Payment Date', border: OutlineInputBorder()),
          child: Text('${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}'),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickSlip(ImageSource.gallery),
              icon: const Icon(CupertinoIcons.photo),
              label: const Text('Choose Slip'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickSlip(ImageSource.camera),
              icon: const Icon(CupertinoIcons.camera),
              label: const Text('Take Photo'),
            ),
          ),
        ],
      ),
      if (_slip != null) Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('Attached: ${_slip!.path.split('/').last}', style: const TextStyle(color: AppColors.success)),
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: (_submitting || !_detailsValid) ? null : _submitBankTransfer,
          child: _submitting
              ? const CupertinoActivityIndicator(color: Colors.white)
              : const Text('Submit Payment for Verification'),
        ),
      ),
    ]);
  }

  Widget _buildStripeForm() {
    return _sectionCard([
      const Text('Card Details', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      CardFormField(controller: _cardController),
      const SizedBox(height: 16),
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: (_submitting || !_detailsValid) ? null : _payWithCard,
          child: _submitting
              ? const CupertinoActivityIndicator(color: Colors.white)
              : const Text('Pay Now'),
        ),
      ),
    ]);
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _textField(TextEditingController controller, String label, {String? hint, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
        ],
      ),
    );
  }
}
