import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../models/application.dart';
import '../../services/application_service.dart';
import '../../widgets/document_style.dart';
import '../../widgets/process_timeline.dart';

/// Read-only view of a submitted application, rendered as the same
/// "official document" the citizen filled in - populated with what they
/// actually submitted, plus its current review status.
class ApplicationDetailScreen extends StatefulWidget {
  final ServiceApplication application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  final _applicationService = ApplicationService();
  late ServiceApplication _application;
  ApplicationTemplate? _template;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _application = widget.application;
    _loadTemplate();
    // The officer can decide on this application while the citizen is
    // looking at it - keep the status/timeline live instead of requiring
    // them to back out and re-open it to see the decision land.
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    try {
      final refreshed = await _applicationService.fetchApplicationById(_application.id);
      if (!mounted) return;
      setState(() => _application = refreshed);
    } catch (_) {
      // Silent - a background refresh failing shouldn't interrupt the UI.
    }
  }

  Future<void> _loadTemplate() async {
    try {
      final template = await _applicationService.fetchTemplateForService(_application.serviceProcedureId);
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

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.danger;
      case 'Revised':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = _application;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(app.applicationReference),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusBanner(app),
                    const SizedBox(height: 16),
                    processTimeline(app, formName: _template?.formName),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: AppColors.danger))
                    else if (_template == null || _template!.fields.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider, width: 0.8),
                        ),
                        child: Text(
                          '${app.serviceName} — this service had no extra form fields at the time of applying.',
                          style: const TextStyle(color: AppColors.secondaryLabel),
                        ),
                      )
                    else
                      _buildDocument(app, _template!),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBanner(ServiceApplication app) {
    final color = _statusColor(app.status);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(app.serviceName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(app.status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(app.department, style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'Submitted ${app.submittedAt.year}-${app.submittedAt.month.toString().padLeft(2, '0')}-${app.submittedAt.day.toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 13),
          ),
          if (app.decisionNotes != null && app.decisionNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Officer note: ${app.decisionNotes}', style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildDocument(ServiceApplication app, ApplicationTemplate template) {
    return documentSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          documentHeader(formName: template.formName, subTitle: template.subTitle),
          const SizedBox(height: 24),
          ...template.fields.map((field) => _buildField(field, app.answers)),
          const SizedBox(height: 24),
          documentFooter(
            presentedBy: app.answers['presentedBy'] ?? '',
            email: app.answers['email'] ?? '',
            telephone: Text(app.answers['telephone'] ?? '-'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TemplateFormField field, Map<String, String> answers) {
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
            decoration: BoxDecoration(color: AppColors.divider.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(6)),
            child: Text('${field.label} — not collected on mobile.', style: const TextStyle(color: AppColors.secondaryLabel, fontSize: 13)),
          ),
        );
      default:
        final value = answers[field.id];
        return documentFieldRow(
          label: field.label,
          required: field.isRequired,
          input: documentBoxedInput(
            Text(value?.isNotEmpty == true ? value! : '-', style: TextStyle(color: value?.isNotEmpty == true ? Colors.black : Colors.grey)),
          ),
        );
    }
  }
}
