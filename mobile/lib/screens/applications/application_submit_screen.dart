import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../models/application.dart';
import '../../services/application_service.dart';

class ApplicationSubmitScreen extends StatefulWidget {
  final int serviceId;
  final String serviceName;

  const ApplicationSubmitScreen({super.key, required this.serviceId, required this.serviceName});

  @override
  State<ApplicationSubmitScreen> createState() => _ApplicationSubmitScreenState();
}

class _ApplicationSubmitScreenState extends State<ApplicationSubmitScreen> {
  final _applicationService = ApplicationService();
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectValues = {};
  final Map<String, Set<String>> _multiSelectValues = {};

  ApplicationTemplate? _template;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool _submitted = false;

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
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    try {
      final template = await _applicationService.fetchTemplateForService(widget.serviceId);
      if (!mounted) return;
      setState(() {
        _template = template;
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
    return answers;
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
      await _applicationService.submitApplication(
        serviceProcedureId: widget.serviceId,
        answers: _collectAnswers(),
      );
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
          : _submitted
              ? _buildSuccess()
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                            ...(_template!.fields.map(_buildField)),
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
                ),
    );
  }

  Widget _buildSuccess() {
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

  Widget _buildField(TemplateFormField field) {
    switch (field.type) {
      case 'heading':
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(field.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        );
      case 'paragraph':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(field.label, style: const TextStyle(color: AppColors.secondaryLabel)),
        );
      case 'file':
      case 'table':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${field.label}${field.isRequired ? ' (required)' : ''} — not collected on mobile yet; please bring this to a service center.',
              style: const TextStyle(color: AppColors.warning, fontSize: 13),
            ),
          ),
        );
      case 'select':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _selectValues[field.id],
            decoration: InputDecoration(labelText: _labelWithRequired(field), border: const OutlineInputBorder()),
            items: field.optionList
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) => setState(() => _selectValues[field.id] = v),
          ),
        );
      case 'multiselect':
        final selected = _multiSelectValues.putIfAbsent(field.id, () => <String>{});
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_labelWithRequired(field), style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 13)),
              Wrap(
                spacing: 8,
                children: field.optionList.map((o) {
                  final isSelected = selected.contains(o);
                  return FilterChip(
                    label: Text(o),
                    selected: isSelected,
                    onSelected: (v) => setState(() => v ? selected.add(o) : selected.remove(o)),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      case 'number':
        final controller = _controllers.putIfAbsent(field.id, () => TextEditingController());
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: _labelWithRequired(field), border: const OutlineInputBorder()),
            validator: (v) => (field.isRequired && (v == null || v.trim().isEmpty)) ? 'Required' : null,
          ),
        );
      case 'textarea':
        final controller = _controllers.putIfAbsent(field.id, () => TextEditingController());
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(labelText: _labelWithRequired(field), border: const OutlineInputBorder()),
            validator: (v) => (field.isRequired && (v == null || v.trim().isEmpty)) ? 'Required' : null,
          ),
        );
      case 'date':
        final controller = _controllers.putIfAbsent(field.id, () => TextEditingController());
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            readOnly: true,
            decoration: InputDecoration(labelText: _labelWithRequired(field), border: const OutlineInputBorder()),
            validator: (v) => (field.isRequired && (v == null || v.trim().isEmpty)) ? 'Required' : null,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              }
            },
          ),
        );
      default: // text
        final controller = _controllers.putIfAbsent(field.id, () => TextEditingController());
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: _labelWithRequired(field), border: const OutlineInputBorder()),
            validator: (v) => (field.isRequired && (v == null || v.trim().isEmpty)) ? 'Required' : null,
          ),
        );
    }
  }

  String _labelWithRequired(TemplateFormField field) => field.isRequired ? '${field.label} *' : field.label;

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
