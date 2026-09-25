import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/installment_plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payment_providers.dart';
import '../../providers/service_providers.dart';
import '../../theme/app_colors.dart';

/// Bank transfer for one installment: shows the account to pay into, then uploads the transfer receipt.
/// Pops `true` once the receipt is submitted (the installment then awaits staff verification).
class BankTransferScreen extends ConsumerStatefulWidget {
  final Installment installment;

  const BankTransferScreen({super.key, required this.installment});

  @override
  ConsumerState<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends ConsumerState<BankTransferScreen> {
  static const _maxReceiptBytes = 10 * 1024 * 1024;

  PlatformFile? _receipt;
  bool _isSubmitting = false;

  Future<void> _pickReceipt() async {
    final List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
    } catch (e) {
      _showMessage('Could not open the file picker: $e', isError: true);
      return;
    }
    if (files.isEmpty || !mounted) return;

    final size = await files.first.length();
    if (size != null && size > _maxReceiptBytes) {
      _showMessage('${files.first.name} is larger than 10 MB.', isError: true);
      return;
    }
    setState(() => _receipt = files.first);
  }

  Future<void> _submit() async {
    final receipt = _receipt;
    if (receipt == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(installmentServiceProvider).submitBankTransfer(
        widget.installment.id,
        fileName: receipt.name,
        bytes: await receipt.readAsBytes(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? AppColors.danger : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.installment.amount.toStringAsFixed(2);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bank Transfer'), backgroundColor: AppColors.cardBg, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Installment #${widget.installment.installmentNumber}',
                    style: const TextStyle(color: AppColors.secondaryLabel)),
                const SizedBox(height: 4),
                Text('LKR $amount',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 4),
                const Text('Transfer exactly this amount, then upload the receipt below.',
                    style: TextStyle(color: AppColors.secondaryLabel, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Transfer to', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _card(child: _buildBankDetails()),
          const SizedBox(height: 16),
          const Text('Transfer receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _card(
            child: _receipt == null
                ? OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _pickReceipt,
                    icon: const Icon(CupertinoIcons.paperclip, size: 18),
                    label: const Text('Upload receipt (PDF, JPG, PNG)'),
                  )
                : Row(children: [
                    const Icon(CupertinoIcons.doc_checkmark, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_receipt!.name, overflow: TextOverflow.ellipsis)),
                    TextButton(onPressed: _isSubmitting ? null : _pickReceipt, child: const Text('Change')),
                  ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _receipt == null || _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A finance officer will verify your receipt. The installment is marked paid once it is approved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondaryLabel, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetails() {
    final bankDetails = ref.watch(bankDetailsProvider);
    if (bankDetails.hasError) {
      return Text(
        bankDetails.error.toString().replaceFirst('Exception: ', ''),
        style: const TextStyle(color: AppColors.danger),
      );
    }
    final details = bankDetails.value;
    if (details == null) return const Center(child: CupertinoActivityIndicator());

    final rows = [
      ('Account name', details['accountName'] ?? ''),
      ('Bank', details['bankName'] ?? ''),
      ('Branch', details['branch'] ?? ''),
      ('Account number', details['accountNumber'] ?? ''),
    ].where((r) => r.$2.isNotEmpty).toList();

    if (rows.isEmpty) {
      return const Text('Bank account details are not configured yet. Please contact the helpdesk.',
          style: TextStyle(color: AppColors.secondaryLabel));
    }

    return Column(
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  SizedBox(width: 120, child: Text(r.$1, style: const TextStyle(color: AppColors.secondaryLabel))),
                  Expanded(child: Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w600))),
                  if (r.$1 == 'Account number')
                    IconButton(
                      tooltip: 'Copy',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: r.$2));
                        _showMessage('Account number copied');
                      },
                    ),
                ]),
              ))
          .toList(),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: child,
      );
}
