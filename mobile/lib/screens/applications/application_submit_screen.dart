import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../models/application.dart';
import '../../services/application_service.dart';
import '../../services/service_api_client.dart';
import '../../services/session_store.dart';
import '../../widgets/document_style.dart';
import '../payment/pay_fee_screen.dart';

/// Renders the officer-built Template as a fillable version of the same
/// "official document" layout used on the web (logo, form name/subtitle/law
/// text header, boxed fields, Presented-by/contact footer) instead of a
/// generic mobile form, so the citizen sees the same document they'd be
/// handed on paper - just editable.
///
/// Beyond the form itself, this screen enforces what the Service Catalog
/// entry actually requires: eligibility rules are checked before submission,
/// any required documents open a document-submission phase after
/// submitting, and if the service has fees, it hands off straight into the
/// payment portal - all driven by the same Service Catalog data (eligibility
/// rules, document requirements, fee schedules) a Verifying Officer set up.
class ApplicationSubmitScreen extends StatefulWidget {
  final int serviceId;
  final String serviceName;

  const ApplicationSubmitScreen({super.key, required this.serviceId, required this.serviceName});

  @override
  State<ApplicationSubmitScreen> createState() => _ApplicationSubmitScreenState();
}

enum _Phase { form, documents, paymentPrompt, done }

class _ApplicationSubmitScreenState extends State<ApplicationSubmitScreen> {
  final _applicationService = ApplicationService();
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectValues = {};
  final Map<String, Set<String>> _multiSelectValues = {};
  final _telephoneController = TextEditingController();

  ApplicationTemplate? _template;
  String _presentedByName = '';
  String _presentedByEmail = '';
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  bool _hasEligibilityRules = false;
  final _ageController = TextEditingController();
  final _citizenshipController = TextEditingController();

  List<Map<String, dynamic>> _documentRequirements = [];
  List<Map<String, dynamic>> _feeSchedules = [];
  final Map<int, File> _pickedDocuments = {};
  bool _uploadingDocs = false;

  _Phase _phase = _Phase.form;
  ServiceApplication? _submittedApplication;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _telephoneController.dispose();
    _ageController.dispose();
    _citizenshipController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    try {
      final template = await _applicationService.fetchTemplateForService(widget.serviceId);
      final user = await SessionStore.getUser();
      final serviceDetails = await ServiceApiClient.fetchServiceDetails(widget.serviceId);
      final eligibilityRules = (serviceDetails['eligibilityRules'] as List?) ?? const [];
      final documentRequirements = (serviceDetails['documentRequirements'] as List?) ?? const [];
      final feeSchedules = (serviceDetails['feeSchedules'] as List?) ?? const [];
      if (!mounted) return;
      setState(() {
        _template = template;
        _presentedByName = (user?['fullName'] as String?) ?? '';
        _presentedByEmail = (user?['email'] as String?) ?? '';
        _hasEligibilityRules = eligibilityRules.isNotEmpty;
        _documentRequirements = documentRequirements.cast<Map<String, dynamic>>();
        _feeSchedules = feeSchedules.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Checks this service's Eligibility Rules against what the citizen enters
  /// here. Returns null when eligible (or the service has no rules to check),
  /// or an explanation to show and block submission on.
  Future<String?> _checkEligibility() async {
    if (!_hasEligibilityRules) return null;

    final age = int.tryParse(_ageController.text.trim());
    if (age == null || _citizenshipController.text.trim().isEmpty) {
      return 'Please fill in your age and citizenship to check eligibility.';
    }

    final result = await ServiceApiClient.evaluateEligibility(widget.serviceId, age, _citizenshipController.text.trim());
    if (result['isEligible'] == true) return null;

    final missing = (result['missingCriteria'] as List?)?.cast<String>() ?? const [];
    final missingText = missing.isNotEmpty ? '\n${missing.join('\n')}' : '';
    return 'You do not meet the requirements for this service.$missingText';
  }

  Map<String, String> _collectAnswers() {
    final answers = <String, String>{};
    for (final field in _template?.fields ?? const <TemplateFormField>[]) {
      switch (field.type) {
        case 'heading':
        case 'paragraph':
        case 'file':
        case 'table':
          break;
        case 'select':
          final value = _selectValues[field.id];
          if (value != null) answers[field.id] = value;
          break;
        case 'multiselect':
          final values = _multiSelectValues[field.id];
          if (values != null && values.isNotEmpty) answers[field.id] = values.join(', ');
          break;
        default:
          final text = _controllers[field.id]?.text.trim();
          if (text != null && text.isNotEmpty) answers[field.id] = text;
      }
    }
    if (_presentedByName.isNotEmpty) answers['presentedBy'] = _presentedByName;
    if (_presentedByEmail.isNotEmpty) answers['email'] = _presentedByEmail;
    if (_telephoneController.text.trim().isNotEmpty) answers['telephone'] = _telephoneController.text.trim();
    return answers;
  }

  void _advancePastSubmission() {
    if (_documentRequirements.isNotEmpty) {
      setState(() => _phase = _Phase.documents);
    } else if (_feeSchedules.isNotEmpty) {
      setState(() => _phase = _Phase.paymentPrompt);
    } else {
      setState(() => _phase = _Phase.done);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? true)) return;

    for (final field in _template?.fields ?? const <TemplateFormField>[]) {
      if (!field.isRequired) continue;
      if (field.type == 'select' && (_selectValues[field.id] == null)) {
        setState(() => _error = '"${field.label}" is required.');
        return;
      }
      if (field.type == 'multiselect' && (_multiSelectValues[field.id]?.isEmpty ?? true)) {
        setState(() => _error = '"${field.label}" is required.');
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final eligibilityError = await _checkEligibility();
      if (eligibilityError != null) {
        setState(() => _error = eligibilityError);
        return;
      }
      final application = await _applicationService.submitApplication(
        serviceProcedureId: widget.serviceId,
        answers: _collectAnswers(),
      );
      if (!mounted) return;
      _submittedApplication = application;
      _advancePastSubmission();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDocument(int requirementId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _pickedDocuments[requirementId] = File(picked.path));
    }
  }

  Future<void> _uploadDocumentsAndContinue() async {
    final missingMandatory = _documentRequirements.where((doc) {
      final isMandatory = doc['isMandatory'] == true;
      final id = doc['id'] as int;
      return isMandatory && !_pickedDocuments.containsKey(id);
    }).toList();

    if (missingMandatory.isNotEmpty) {
      setState(() => _error = 'Please attach: ${missingMandatory.map((d) => d['documentName']).join(', ')}');
      return;
    }

    setState(() {
      _uploadingDocs = true;
      _error = null;
    });
    try {
      for (final doc in _documentRequirements) {
        final id = doc['id'] as int;
        final file = _pickedDocuments[id];
        if (file == null) continue;
        await _applicationService.uploadDocument(
          applicationId: _submittedApplication!.id,
          documentRequirementId: id,
          documentName: doc['documentName'] as String,
          file: file,
        );
      }
      if (!mounted) return;
      if (_feeSchedules.isNotEmpty) {
        setState(() => _phase = _Phase.paymentPrompt);
      } else {
        setState(() => _phase = _Phase.done);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploadingDocs = false);
    }
  }

  double get _totalFeeAmount => _feeSchedules.fold(0.0, (sum, f) => sum + ((f['amount'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Apply: ${widget.serviceName}'),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : switch (_phase) {
              _Phase.form => _buildFormPhase(),
              _Phase.documents => _buildDocumentsPhase(),
              _Phase.paymentPrompt => _buildPaymentPromptPhase(),
              _Phase.done => _buildDonePhase(),
            },
    );
  }

  Widget _buildFormPhase() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasEligibilityRules) ...[
                _buildEligibilitySection(),
                const SizedBox(height: 16),
              ],
              if (_template == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider, width: 0.8),
                  ),
                  child: const Text(
                    'This service has no extra form fields configured. You can submit your application now and an officer will follow up if more information is needed.',
                    style: TextStyle(color: AppColors.secondaryLabel),
                  ),
                )
              else
                _buildDocument(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _errorBanner(_error!),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsPhase() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.success, size: 40),
            const SizedBox(height: 8),
            const Text('Application Submitted', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Reference: ${_submittedApplication?.applicationReference ?? ''}',
              style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Text('Required Documents', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            const Text(
              'This service needs the following documents. Attach each one to continue.',
              style: TextStyle(color: AppColors.secondaryLabel, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ..._documentRequirements.map(_buildDocumentRequirementRow),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _errorBanner(_error!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _uploadingDocs ? null : _uploadDocumentsAndContinue,
                child: _uploadingDocs
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text('Upload & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRequirementRow(Map<String, dynamic> doc) {
    final id = doc['id'] as int;
    final name = doc['documentName'] as String? ?? 'Document';
    final description = doc['description'] as String?;
    final isMandatory = doc['isMandatory'] == true;
    final picked = _pickedDocuments[id];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    if (isMandatory) const Text(' *', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
                if (description != null && description.isNotEmpty)
                  Text(description, style: const TextStyle(fontSize: 12, color: AppColors.secondaryLabel)),
                if (picked != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Attached: ${picked.path.split('/').last}', style: const TextStyle(fontSize: 12, color: AppColors.success)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _pickDocument(id),
            child: Text(picked == null ? 'Attach' : 'Replace'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPromptPhase() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.money_dollar_circle_fill, color: AppColors.primary, size: 56),
            const SizedBox(height: 16),
            const Text('A Fee Is Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'This service requires a fee of ${_feeSchedules.first['feeType'] ?? 'Application Fee'}: LKR ${_totalFeeAmount.toStringAsFixed(2)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryLabel),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PayFeeScreen(
                        initialServiceName: widget.serviceName,
                        initialApplicationId: _submittedApplication?.applicationReference,
                        initialAmount: _totalFeeAmount,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  setState(() => _phase = _Phase.done);
                },
                child: const Text('Pay Now'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _phase = _Phase.done),
              child: const Text('Pay Later from My Payments'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonePhase() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text('Application Submitted', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'A Verifying Officer will review your application. Track its status from My Applications.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryLabel),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Eligibility Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'This service has eligibility requirements. We check these before your application is submitted.',
            style: TextStyle(color: AppColors.secondaryLabel, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Your Age', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _citizenshipController,
            decoration: const InputDecoration(labelText: 'Citizenship', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDocument() {
    final template = _template!;
    return documentSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          documentHeader(formName: template.formName, subTitle: template.subTitle),
          const SizedBox(height: 24),
          if (template.fields.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No elements added to this form.', style: TextStyle(color: AppColors.secondaryLabel, fontStyle: FontStyle.italic)),
              ),
            )
          else
            ...template.fields.map(_buildField),
          const SizedBox(height: 24),
          documentFooter(
            presentedBy: _presentedByName,
            email: _presentedByEmail,
            telephone: TextField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TemplateFormField field) {
    switch (field.type) {
      case 'heading':
        return documentHeading(field.label);
      case 'paragraph':
        return documentParagraph(field.label);
      case 'file':
      case 'table':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
            child: Text(
              '${field.label}${field.isRequired ? ' (required)' : ''} — not collected on mobile yet; please bring this to a service center.',
              style: const TextStyle(color: AppColors.warning, fontSize: 13),
            ),
          ),
        );
      case 'select':
        return documentFieldRow(
          label: field.label,
          required: field.isRequired,
          input: documentBoxedInput(
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectValues[field.id],
                hint: const Text('Select...', style: TextStyle(color: Colors.grey)),
                items: field.optionList.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (v) => setState(() => _selectValues[field.id] = v),
              ),
            ),
          ),
        );
      case 'multiselect':
        final selected = _multiSelectValues.putIfAbsent(field.id, () => <String>{});
        return documentFieldRow(
          label: field.label,
          required: field.isRequired,
          input: documentBoxedInput(
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: field.optionList.map((o) {
                final isSelected = selected.contains(o);
                return FilterChip(
                  label: Text(o, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (v) => setState(() => v ? selected.add(o) : selected.remove(o)),
                );
              }).toList(),
            ),
          ),
        );
      case 'number':
        final controller = _controllers.putIfAbsent(field.id, () => TextEditingController());
        return documentFieldRow(
          label: field.label,
          required: field.isRequired,
          input: documentBoxedInput(
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              validator: (v) => (field.isRequired && (v == null || v.trim().isEmpty)) ? 'Required' : null,
            ),
          ),
        );
      case 'textarea':
        final controller = _controllers.putIfAbsent(field.id, () => TextEditingController());
        return documentFieldRow(
          label: field.label,
          required: field.isRequired,
          input: documentBoxedInput(
            TextFormField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              validator: (v) => (field.isRequired && (v == null || v.trim().isEmpty)) ? 'Required' : null,
            ),
          ),
        );
      case 'date':
        final controller = _controllers.putIfAbsent(field.id, () => TextEditingController());
        return documentFieldRow(
          label: field.label,
          required: field.isRequired,
          input: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                setState(() {});
              }
            },
            child: documentBoxedInput(
              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? 'DD / MM / YYYY' : controller.text,
                      style: TextStyle(color: controller.text.isEmpty ? Colors.grey : Colors.black),
                    ),
                  ),
                  const Icon(CupertinoIcons.calendar, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      default: // text
        final controller = _controllers.putIfAbsent(field.id, () => TextEditingController());
        return documentFieldRow(
          label: field.label,
          required: field.isRequired,
          input: documentBoxedInput(
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              validator: (v) => (field.isRequired && (v == null || v.trim().isEmpty)) ? 'Required' : null,
            ),
          ),
        );
    }
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
