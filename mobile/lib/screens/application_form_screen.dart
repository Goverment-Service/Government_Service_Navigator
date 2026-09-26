import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/application_providers.dart';
import '../providers/catalog_providers.dart';
import '../providers/session_provider.dart';
import '../services/service_api_client.dart';
import 'payments/payment_screen.dart';

/// Renders the admin-built application template as a paper-style government form
/// (matching the web Template Builder canvas) and submits the citizen's answers.
class ApplicationFormScreen extends ConsumerStatefulWidget {
  final int serviceId;
  final String serviceName;
  final int? stageNumber;
  final int? applicationId;

  const ApplicationFormScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    this.stageNumber,
    this.applicationId,
  });

  @override
  ConsumerState<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends ConsumerState<ApplicationFormScreen> {
  static const _ink = Color(0xFF000000);
  static const _faint = Color(0xFF999999);
  static const _tableHeaderBg = Color(0xFFE0E0E0);
  static const _displayOnly = {'heading', 'paragraph'};

  // Footer keys, sent alongside the template answers.
  static const _presentedByKey = 'Presented by';
  static const _emailKey = 'Email';
  static const _telephoneKey = 'Telephone';

  static const _maxDocumentBytes = 10 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  Map<String, dynamic>? _submitted;

  /// Saved application waiting for its fee to be paid (response from submit / finalize).
  Map<String, dynamic>? _pendingPayment;
  bool _isFinalizing = false;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectValues = {};
  final Map<String, Set<String>> _multiValues = {};

  /// File fields: label -> uploaded document (id from the backend), plus labels still uploading.
  final Map<String, ({String id, String fileName})> _documents = {};
  final Set<String> _uploading = {};

  /// Payment field mode: label -> 'slip' (default bank deposit slip) | 'online' (online ref ID)
  final Map<String, String> _paymentModes = {};

  /// Table fields: label -> rows -> one controller per column.
  final Map<String, List<List<TextEditingController>>> _tableRows = {};

  Map<String, dynamic>? _stageFormResponse;
  bool _isLoadingStageForm = false;
  String? _stageFormError;

  bool get _isStageMode => widget.stageNumber != null && widget.stageNumber! > 1;

  @override
  void initState() {
    super.initState();
    if (_isStageMode) {
      _loadStageForm();
    } else {
      // Prefill the footer from the department once the form has loaded
      ref.listenManual(applicationFormDataProvider(widget.serviceId), (previous, next) {
        final department = next.value?.department;
        if (previous?.value != null || next.value == null) return;
        _controllerFor(_presentedByKey).text = department?['name']?.toString() ?? '';
        _controllerFor(_emailKey).text = department?['email']?.toString() ?? '';
      }, fireImmediately: true);
    }
  }

  Future<void> _loadStageForm() async {
    setState(() {
      _isLoadingStageForm = true;
      _stageFormError = null;
    });
    try {
      final token = ref.read(authTokenProvider);
      final form = await ServiceApiClient.fetchApplicationForm(
        widget.serviceId,
        token,
        stage: widget.stageNumber,
      );
      if (form != null) {
        setState(() {
          _stageFormResponse = form;
          _isLoadingStageForm = false;
        });
        final department = form['department'] as Map<String, dynamic>?;
        _controllerFor(_presentedByKey).text = department?['name']?.toString() ?? '';
        _controllerFor(_emailKey).text = department?['email']?.toString() ?? '';
      } else {
        setState(() {
          _isLoadingStageForm = false;
          _stageFormError = 'Stage ${widget.stageNumber} form is not yet published.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStageForm = false;
        _stageFormError = 'Could not load Stage ${widget.stageNumber} form.';
      });
    }
  }

  // Loaded form data. Read (not watched) so these are safe in callbacks; [build] watches.
  AsyncValue<ApplicationFormData> get _formState => ref.read(applicationFormDataProvider(widget.serviceId));
  bool get _isLoading => _isStageMode ? _isLoadingStageForm : _formState.isLoading;
  String? get _loadError => _isStageMode
      ? _stageFormError
      : (_formState.hasError ? 'Could not load the application form.' : null);
  Map<String, dynamic>? get _template => _isStageMode
      ? (_stageFormResponse?['template'] as Map<String, dynamic>?)
      : _formState.value?.template;
  List<Map<String, dynamic>> get _fields {
    if (_isStageMode) {
      final fields = (_template?['fields'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList()
        ..sort((a, b) => ((a['orderIndex'] ?? 0) as int).compareTo((b['orderIndex'] ?? 0) as int));
      return fields;
    }
    return _formState.value?.fields ?? const [];
  }

  /// The service's required documents from the catalog. For multi-stage services (or when an active form template defines its own fields),
  /// file requirements belong to their respective stage templates, so catalog-wide docs are not dumped into Stage 1.
  List<RequiredDocument> get _requiredDocs {
    if (_isStageMode || _totalStages > 1) return const [];
    final hasFileField = _fields.any((f) => f['type'] == 'file');
    if (hasFileField) return const [];
    return _formState.value?.requiredDocs ?? const [];
  }

  int get _currentStage => _isStageMode
      ? (widget.stageNumber ?? 1)
      : (_formState.value?.stage ?? widget.stageNumber ?? 1);
  int get _totalStages => _formState.value?.totalStages ?? 1;
  List<String> get _workflowDepartments => _formState.value?.workflowDepartments ?? const [];
  String get _stageDepartment {
    if (_isStageMode && _stageFormResponse != null && _stageFormResponse!['department'] != null) {
      return _stageFormResponse!['department']['name']?.toString() ?? 'Assigned Department';
    }
    final dept = _formState.value?.stageDepartment;
    if (dept != null && dept.isNotEmpty) return dept;
    final tDept = _template?['department']?.toString();
    if (tDept != null && tDept.isNotEmpty) return tDept;
    if (_workflowDepartments.isNotEmpty && _currentStage - 1 < _workflowDepartments.length) {
      return _workflowDepartments[_currentStage - 1];
    }
    return 'Assigned Department';
  }

  String? get _stageDescription {
    if (_isStageMode && _stageFormResponse != null) {
      return _stageFormResponse!['stageDescription']?.toString();
    }
    return _formState.value?.stageDescription;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final rows in _tableRows.values) {
      for (final row in rows) {
        for (final c in row) {
          c.dispose();
        }
      }
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String label) =>
      _controllers.putIfAbsent(label, () => TextEditingController());

  List<String> _optionsOf(Map<String, dynamic> field) => (field['options']?.toString() ?? '')
      .split(',')
      .map((o) => o.trim())
      .where((o) => o.isNotEmpty)
      .toList();

  /// Same default columns as the web builder when none are configured.
  List<String> _columnsOf(Map<String, dynamic> field) {
    final cols = _optionsOf(field);
    return cols.isEmpty ? const ['Col 1', 'Col 2'] : cols;
  }

  List<List<TextEditingController>> _rowsFor(String label, int columnCount) =>
      _tableRows.putIfAbsent(
        label,
        () => List.generate(2, (_) => List.generate(columnCount, (_) => TextEditingController())),
      );

  Map<String, String> _collectAnswers() {
    final answers = <String, String>{};
    for (final field in _fields) {
      final type = field['type']?.toString() ?? 'text';
      final label = field['label']?.toString() ?? '';
      if (_displayOnly.contains(type) || label.isEmpty) continue;

      switch (type) {
        case 'select':
          answers[label] = _selectValues[label] ?? '';
        case 'multiselect':
          answers[label] = (_multiValues[label] ?? {}).join(', ');
        case 'file':
          answers[label] = _documents[label]?.fileName ?? '';
        case 'table':
          // Non-empty rows as a JSON list of {column: value} objects.
          final columns = _columnsOf(field);
          final rows = (_tableRows[label] ?? [])
              .map((row) => {for (var i = 0; i < columns.length; i++) columns[i]: row[i].text.trim()})
              .where((row) => row.values.any((v) => v.isNotEmpty))
              .toList();
          answers[label] = rows.isEmpty ? '' : jsonEncode(rows);
        case 'payment':
          final mode = _paymentModes[label] ?? 'slip';
          if (mode == 'slip') {
            final fileName = _documents[label]?.fileName ?? '';
            answers[label] = fileName.isNotEmpty ? 'Bank Deposit Slip: $fileName' : '';
          } else {
            final ref = _controllers[label]?.text.trim() ?? '';
            answers[label] = ref.isNotEmpty ? 'Online Ref: $ref' : '';
          }
        default:
          answers[label] = _controllers[label]?.text.trim() ?? '';
      }
    }
    for (final key in [_presentedByKey, _emailKey, _telephoneKey]) {
      answers[key] = _controllers[key]?.text.trim() ?? '';
    }
    return answers;
  }

  Future<void> _submit() async {
    if (_uploading.isNotEmpty) {
      _showError('Please wait for your documents to finish uploading.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final Map<String, dynamic> result;
      if (_isStageMode && widget.applicationId != null) {
        result = await ServiceApiClient.submitStageApplication(
          applicationId: widget.applicationId!,
          templateId: _template?['id']?.toString() ?? '',
          answers: _collectAnswers(),
          documents: {for (final e in _documents.entries) e.key: e.value.id},
          token: ref.read(authTokenProvider),
        );
      } else {
        result = await ServiceApiClient.submitApplication(
          serviceId: widget.serviceId,
          templateId: _template?['id']?.toString(),
          answers: _collectAnswers(),
          documents: {for (final e in _documents.entries) e.key: e.value.id},
          token: ref.read(authTokenProvider),
        );
      }
      if (!mounted) return;
      ref.invalidate(myApplicationsProvider);
      if (result['paymentRequired'] == true) {
        // Saved, but only sent to the officers once the fee is paid
        setState(() => _pendingPayment = result);
        await _pay();
      } else {
        setState(() => _submitted = result);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Opens the payment screen for the outstanding fee, then asks the backend to finalize the application.
  Future<void> _pay() async {
    final pending = _pendingPayment;
    if (pending == null) return;

    await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) => PaymentScreen(
          userEmail: pending['userEmail']?.toString() ?? '',
          applicationId: pending['applicationId'].toString(),
          amount: (pending['amount'] as num).toDouble(),
          popOnPaid: true,
        ),
      ),
    );
    if (!mounted) return;
    await _finalize();
  }

  /// The backend checks the payments itself, so this is also safe to call when the user backed out.
  Future<void> _finalize() async {
    final pending = _pendingPayment;
    if (pending == null) return;

    setState(() => _isFinalizing = true);
    try {
      final result = await ServiceApiClient.finalizeApplication(
        applicationId: (pending['applicationId'] as num).toInt(),
        token: ref.read(authTokenProvider),
      );
      if (!mounted) return;
      ref.invalidate(myApplicationsProvider);
      setState(() {
        if (result['paymentRequired'] == true) {
          _pendingPayment = result;
        } else {
          _pendingPayment = null;
          _submitted = result;
        }
      });
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(applicationFormDataProvider(widget.serviceId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.serviceName),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_submitted != null) return _buildSuccess();
    if (_pendingPayment != null) return _buildPaymentPending();
    if (_loadError != null) return _buildMessage(CupertinoIcons.exclamationmark_triangle, _loadError!);
    if (_template == null) {
      return _buildMessage(
        CupertinoIcons.doc_text,
        'An application form has not been published for this service yet. Please check back later.',
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Sequential Multi-Department Workflow Stepper & Info
          _buildStageWorkflowHeader(),

          // The "paper" sheet
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFCCCCCC)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Theme(
              data: _paperTheme(context),
              child: DefaultTextStyle(
                style: const TextStyle(color: _ink, fontSize: 14, height: 1.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStageGateBadge(),
                    _buildHeader(),
                    const SizedBox(height: 28),
                    ..._fields.map(_buildField),
                    if (_requiredDocs.isNotEmpty) ..._buildRequiredDocuments(),
                    const SizedBox(height: 28),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _totalStages > 1
                          ? 'Submit Stage $_currentStage & Proceed'
                          : 'Submit & Proceed',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          if (_totalStages > 1) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Submission will be routed directly to $_stageDepartment for official verification before Stage ${(_currentStage + 1).clamp(1, _totalStages)} unlocks.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.secondaryLabel),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStageWorkflowHeader() {
    if (_totalStages <= 1 && _workflowDepartments.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = _totalStages > 1 ? _totalStages : (_workflowDepartments.isNotEmpty ? _workflowDepartments.length : 1);
    final stages = _workflowDepartments.isNotEmpty
        ? _workflowDepartments
        : List.generate(total, (i) => i == 0 ? _stageDepartment : 'Department Stage ${i + 1}');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0E2FF)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF5FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.account_tree_outlined, color: Color(0xFF0F62FE), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sequential Verification Workflow',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF161616)),
                    ),
                    Text(
                      'Stage $_currentStage of $total • $_stageDepartment',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F62FE)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD0E2FF)),
                ),
                child: Text(
                  'STAGE $_currentStage / $total',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F62FE)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stepper chain
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < total; i++) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (i + 1 == _currentStage)
                              ? const Color(0xFF0F62FE)
                              : (i + 1 < _currentStage)
                                  ? const Color(0xFF24A148)
                                  : const Color(0xFFE0E0E0),
                        ),
                        alignment: Alignment.center,
                        child: (i + 1 < _currentStage)
                            ? const Icon(Icons.check, size: 15, color: Colors.white)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: (i + 1 == _currentStage) ? Colors.white : const Color(0xFF525252),
                                ),
                              ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stage ${i + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: (i + 1 == _currentStage) ? const Color(0xFF0F62FE) : const Color(0xFF525252),
                            ),
                          ),
                          Text(
                            i < stages.length ? stages[i] : 'Dept ${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: (i + 1 == _currentStage) ? FontWeight.w600 : FontWeight.normal,
                              color: (i + 1 == _currentStage) ? const Color(0xFF161616) : const Color(0xFF8D8D8D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (i < total - 1)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 24,
                      height: 2,
                      color: (i + 1 < _currentStage) ? const Color(0xFF24A148) : const Color(0xFFE0E0E0),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFF525252)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    total > 1
                        ? 'You are filling Stage $_currentStage for $_stageDepartment. Once verified, the application advances to Stage ${(_currentStage + 1).clamp(1, total)}.'
                        : 'Official application form for $_stageDepartment verification.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF525252), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageGateBadge() {
    if (_totalStages <= 1 && _workflowDepartments.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = _totalStages > 1 ? _totalStages : (_workflowDepartments.isNotEmpty ? _workflowDepartments.length : 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        border: Border.all(color: const Color(0xFF0F62FE), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF0F62FE), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STAGE $_currentStage OF $total APPLICATION GATE • ${_stageDepartment.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF0F62FE),
                  ),
                ),
                if (_stageDescription != null && _stageDescription!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _stageDescription!,
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF525252)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header: Logo | Form name / subtitle / law text | Emblem / QR ──────────────
  Widget _buildHeader() {
    final subTitle = _template!['subTitle']?.toString() ?? '';
    final lawText = _template!['lawText']?.toString() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFCCCCCC))),
          child: const Text('Logo', style: TextStyle(fontSize: 10, color: _faint)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  _template!['formName']?.toString() ?? widget.serviceName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (subTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subTitle.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                ],
                if (lawText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(lawText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ),
        Container(
          width: 64,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCCCCCC))),
          child: const Text('Emblem / QR', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: _faint)),
        ),
      ],
    );
  }

  // ── Fields ────────────────────────────────────────────────────────────────────
  Widget _buildField(Map<String, dynamic> field) {
    final type = field['type']?.toString() ?? 'text';
    final label = field['label']?.toString() ?? '';
    final required = field['isRequired'] == true;

    String? requiredValidator(String? v) =>
        required && (v == null || v.trim().isEmpty) ? '$label is required' : null;

    switch (type) {
      case 'heading':
        return Container(
          margin: const EdgeInsets.only(top: 16, bottom: 12),
          padding: const EdgeInsets.only(bottom: 4),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _ink, width: 2))),
          child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        );

      case 'paragraph':
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(label, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
        );

      case 'table':
        return _buildTable(field, label, required);

      case 'textarea':
        return _labelled(
          label,
          required,
          alignTop: true,
          child: TextFormField(
            controller: _controllerFor(label),
            minLines: 3,
            maxLines: 6,
            decoration: _boxDecoration(),
            validator: requiredValidator,
          ),
        );

      case 'number':
        return _labelled(
          label,
          required,
          child: TextFormField(
            controller: _controllerFor(label),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _boxDecoration(),
            validator: (v) {
              final err = requiredValidator(v);
              if (err != null) return err;
              if (v != null && v.trim().isNotEmpty && num.tryParse(v.trim()) == null) {
                return 'Enter a valid number';
              }
              return null;
            },
          ),
        );

      case 'date':
        final controller = _controllerFor(label);
        return _labelled(
          label,
          required,
          child: TextFormField(
            controller: controller,
            readOnly: true,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'DD / MM / YYYY',
              hintStyle: TextStyle(color: Color(0xFF666666)),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _ink)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
            ),
            validator: requiredValidator,
            onTap: () async {
              final parts = controller.text.split(' / ');
              final current = parts.length == 3
                  ? DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}')
                  : null;
              final picked = await showDatePicker(
                context: context,
                initialDate: current ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                String two(int n) => n.toString().padLeft(2, '0');
                controller.text = '${two(picked.day)} / ${two(picked.month)} / ${picked.year}';
              }
            },
          ),
        );

      case 'select':
        final options = _optionsOf(field);
        return _labelled(
          label,
          required,
          child: DropdownButtonFormField<String>(
            initialValue: _selectValues[label],
            isExpanded: true,
            hint: const Text('Select', style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
            decoration: _boxDecoration(),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (v) => setState(() => _selectValues[label] = v),
            validator: requiredValidator,
          ),
        );

      case 'multiselect':
        final options = _optionsOf(field);
        final selected = _multiValues.putIfAbsent(label, () => <String>{});
        return _labelled(
          label,
          required,
          alignTop: true,
          child: FormField<Set<String>>(
            validator: (_) => required && selected.isEmpty ? 'Select at least one option' : null,
            builder: (state) => InputDecorator(
              decoration: _boxDecoration().copyWith(errorText: state.errorText),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: options
                    .map((o) => FilterChip(
                          label: Text(o, style: const TextStyle(fontSize: 12)),
                          selected: selected.contains(o),
                          visualDensity: VisualDensity.compact,
                          onSelected: (on) {
                            setState(() => on ? selected.add(o) : selected.remove(o));
                            state.didChange(selected);
                          },
                        ))
                    .toList(),
              ),
            ),
          ),
        );

      case 'file':
        return _labelled(label, required, child: _buildFilePicker(label, required));

      case 'payment':
        double amount = 0;
        String feeType = label;
        String methods = 'Online Card, Manual Bank Deposit Slip';
        final rawOptions = field['options'];
        if (rawOptions is Map) {
          amount = (rawOptions['amount'] as num?)?.toDouble() ?? 0;
          feeType = rawOptions['feeType']?.toString() ?? feeType;
          methods = rawOptions['methods']?.toString() ?? methods;
        } else if (rawOptions is String && rawOptions.trim().startsWith('{')) {
          try {
            final parsed = jsonDecode(rawOptions);
            if (parsed is Map) {
              amount = (parsed['amount'] as num?)?.toDouble() ?? 0;
              feeType = parsed['feeType']?.toString() ?? feeType;
              methods = parsed['methods']?.toString() ?? methods;
            }
          } catch (_) {}
        } else if (rawOptions is num) {
          amount = rawOptions.toDouble();
        }

        final controller = _controllerFor(label);
        if (controller.text.isEmpty && amount > 0) {
          controller.text = amount.toStringAsFixed(2);
        }

        return _buildPaymentSection(
          label: label,
          feeType: feeType,
          amount: amount,
          methods: methods,
          required: required,
          controller: controller,
        );

      default: // text
        return _labelled(
          label,
          required,
          child: TextFormField(
            controller: _controllerFor(label),
            decoration: _boxDecoration(),
            validator: requiredValidator,
          ),
        );
    }
  }

  /// "Required Documents" section: one upload per document the service catalog lists.
  List<Widget> _buildRequiredDocuments() => [
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 12),
          padding: const EdgeInsets.only(bottom: 6),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _ink, width: 2))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _totalStages > 1
                    ? 'STAGE $_currentStage REQUIRED DOCUMENTS'
                    : 'REQUIRED SUPPORTING DOCUMENTS',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF8D8D8D)),
                ),
                child: Text(
                  '${_requiredDocs.length} Document${_requiredDocs.length > 1 ? "s" : ""}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        ..._requiredDocs.map((doc) => _labelled(
              doc.name,
              doc.isMandatory,
              alignTop: doc.description.isNotEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilePicker(doc.name, doc.isMandatory),
                  if (doc.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(doc.description, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                    ),
                ],
              ),
            )),
      ];

  /// Picks a PDF / JPEG / PNG and uploads it straight away, so problems show up before submitting.
  Future<void> _pickDocument(String label, FormFieldState<void> state) async {
    final List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
    } catch (e) {
      _showError('Could not open the file picker: $e');
      return;
    }
    if (files.isEmpty || !mounted) return;
    final file = files.first;

    final size = await file.length();
    if (size != null && size > _maxDocumentBytes) {
      _showError('${file.name} is larger than 10 MB.');
      return;
    }

    setState(() => _uploading.add(label));
    try {
      final uploaded = await ServiceApiClient.uploadDocument(
        fieldLabel: label,
        fileName: file.name,
        bytes: await file.readAsBytes(),
        token: ref.read(authTokenProvider),
      );
      if (!mounted) return;
      setState(() => _documents[label] = (
            id: uploaded['id'].toString(),
            fileName: uploaded['fileName']?.toString() ?? file.name,
          ));
      state.didChange(null);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploading.remove(label));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildFilePicker(String label, bool required) {
    return FormField<void>(
      validator: (_) => required && !_documents.containsKey(label) ? '$label is required' : null,
      builder: (state) {
        final document = _documents[label];
        final uploading = _uploading.contains(label);

        final Widget content;
        if (uploading) {
          content = const Row(children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Uploading…', style: TextStyle(fontSize: 13)),
          ]);
        } else if (document != null) {
          content = Row(children: [
            const Icon(CupertinoIcons.doc_checkmark, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(document.fileName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            ),
            IconButton(
              tooltip: 'Replace file',
              visualDensity: VisualDensity.compact,
              icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 18),
              onPressed: _isSubmitting ? null : () => _pickDocument(label, state),
            ),
            IconButton(
              tooltip: 'Remove file',
              visualDensity: VisualDensity.compact,
              icon: const Icon(CupertinoIcons.xmark, size: 18),
              onPressed: _isSubmitting
                  ? null
                  : () {
                      setState(() => _documents.remove(label));
                      state.didChange(null);
                    },
            ),
          ]);
        } else {
          content = OutlinedButton.icon(
            onPressed: _isSubmitting ? null : () => _pickDocument(label, state),
            icon: const Icon(CupertinoIcons.paperclip, size: 18),
            label: const Text('Choose file (PDF, JPG, PNG)', style: TextStyle(fontSize: 12)),
          );
        }

        return InputDecorator(
          decoration: _boxDecoration().copyWith(
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            errorText: state.errorText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          child: content,
        );
      },
    );
  }

  Widget _buildPaymentSection({
    required String label,
    required String feeType,
    required double amount,
    required String methods,
    required bool required,
    required TextEditingController controller,
  }) {
    final currentMode = _paymentModes[label] ?? 'slip';

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        border: Border.all(color: const Color(0xFF0F62FE), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F62FE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(CupertinoIcons.creditcard, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'STATUTORY PAYMENT REQUIRED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (required)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'MANDATORY',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.isNotEmpty ? label : feeType,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Accepted: $methods',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF525252)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD0E2FF)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Payable Fee', style: TextStyle(fontSize: 9, color: Color(0xFF525252))),
                          Text(
                            'LKR ${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F62FE),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Payment mode switcher: Bank Deposit Slip vs Online Ref ID
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5EFFF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD0E2FF)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _paymentModes[label] = 'slip';
                              controller.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: currentMode == 'slip' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: currentMode == 'slip'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.doc_text,
                                  size: 14,
                                  color: currentMode == 'slip' ? const Color(0xFF0F62FE) : const Color(0xFF525252),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Bank Deposit Slip',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: currentMode == 'slip' ? FontWeight.bold : FontWeight.w500,
                                    color: currentMode == 'slip' ? const Color(0xFF0F62FE) : const Color(0xFF525252),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _paymentModes[label] = 'online';
                              _documents.remove(label);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: currentMode == 'online' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: currentMode == 'online'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.creditcard,
                                  size: 14,
                                  color: currentMode == 'online' ? const Color(0xFF0F62FE) : const Color(0xFF525252),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Online Ref ID',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: currentMode == 'online' ? FontWeight.bold : FontWeight.w500,
                                    color: currentMode == 'online' ? const Color(0xFF0F62FE) : const Color(0xFF525252),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (currentMode == 'slip')
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(CupertinoIcons.arrow_up_doc, size: 14, color: Color(0xFF0F62FE)),
                            SizedBox(width: 6),
                            Text(
                              'Upload Bank Deposit Slip / Payment Evidence',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Upload stamped deposit slip or payment receipt for official departmental finance audit.',
                          style: TextStyle(fontSize: 10, color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 8),
                        _buildFilePicker(label, required),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(CupertinoIcons.checkmark_shield, size: 14, color: Color(0xFF0F62FE)),
                            SizedBox(width: 6),
                            Text(
                              'Online Payment / Transfer Reference ID',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Enter the reference number or transaction ID from your confirmation email or banking transfer.',
                          style: TextStyle(fontSize: 10, color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: controller,
                          decoration: _boxDecoration().copyWith(
                            hintText: 'e.g. TXN-984210 / REF-123456',
                            hintStyle: const TextStyle(color: Color(0xFF8D8D8D), fontSize: 13),
                          ),
                          validator: (v) {
                            if (required && (v == null || v.trim().isEmpty)) {
                              return '$label reference ID is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 6),
                Text(
                  currentMode == 'slip'
                      ? 'Deposit slips and receipts are audited by the Department Finance Officer before stage clearance.'
                      : 'Online transaction reference IDs are audited and cleared against gateway statements.',
                  style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF525252)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Label :" on the left (30%), input on the right — the web builder's row layout.
  Widget _labelled(String label, bool required, {required Widget child, bool alignTop = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.only(right: 8, top: alignTop ? 10 : 0),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: label),
                    if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
                    const TextSpan(text: ' :'),
                  ],
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(flex: 7, child: child),
        ],
      ),
    );
  }

  Widget _buildTable(Map<String, dynamic> field, String label, bool required) {
    final columns = _columnsOf(field);
    final rows = _rowsFor(label, columns.length);
    const cellBorder = BorderSide(color: _ink);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FormField<void>(
        validator: (_) => required && rows.every((r) => r.every((c) => c.text.trim().isEmpty))
            ? '$label: fill in at least one row'
            : null,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label.isNotEmpty && label != 'Table')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: label),
                    if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
                  ]),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            Table(
              border: const TableBorder(
                top: cellBorder,
                bottom: cellBorder,
                left: cellBorder,
                right: cellBorder,
                horizontalInside: cellBorder,
                verticalInside: cellBorder,
              ),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: _tableHeaderBg),
                  children: columns
                      .map((c) => Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(c, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                ),
                ...rows.map((row) => TableRow(
                      children: row
                          .map((controller) => TextField(
                                controller: controller,
                                style: const TextStyle(fontSize: 13),
                                onChanged: (_) => state.didChange(null),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                              ))
                          .toList(),
                    )),
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => rows.add(
                        List.generate(columns.length, (_) => TextEditingController()),
                      )),
                  icon: const Icon(CupertinoIcons.add, size: 16),
                  label: const Text('Add row'),
                ),
                if (rows.length > 1)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      for (final c in rows.removeLast()) {
                        c.dispose();
                      }
                    }),
                    icon: const Icon(CupertinoIcons.minus, size: 16),
                    label: const Text('Remove row'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  ),
              ],
            ),
            if (state.hasError)
              Text(state.errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ── Footer: Presented by | Email / Telephone ──────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _ink, width: 2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Presented by:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          // Filled from the service's department; not editable by the applicant.
          TextFormField(
            controller: _controllerFor(_presentedByKey),
            readOnly: true,
            minLines: 3,
            maxLines: 4,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: _boxDecoration(),
          ),
          const SizedBox(height: 14),
          _footerBox(
            'Email:',
            // Department Admin's email; not editable by the applicant.
            TextFormField(
              controller: _controllerFor(_emailKey),
              readOnly: true,
              decoration: _cellDecoration().copyWith(hintText: 'Not assigned'),
            ),
          ),
          const SizedBox(height: 8),
          _footerBox(
            'Telephone:',
            TextFormField(
              controller: _controllerFor(_telephoneKey),
              keyboardType: TextInputType.phone,
              decoration: _cellDecoration(),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.isEmpty) return 'Telephone is required';
                if (digits.length < 9) return 'Enter a valid phone number';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Bordered "Label | input" cell pair, as in the web footer.
  Widget _footerBox(String label, Widget input) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: _ink)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 92,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(border: Border(right: BorderSide(color: _ink))),
              child: Text(label, style: const TextStyle(fontSize: 13)),
            ),
            Expanded(child: input),
          ],
        ),
      ),
    );
  }

  ThemeData _paperTheme(BuildContext context) {
    final light = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light),
    );
    return light.copyWith(
      textTheme: light.textTheme.apply(bodyColor: _ink, displayColor: _ink),
      inputDecorationTheme: const InputDecorationTheme(filled: false),
    );
  }

  InputDecoration _boxDecoration() => const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: _ink)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: _ink)),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.primary, width: 2)),
      );

  InputDecoration _cellDecoration() => const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      );

  Widget _buildMessage(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.secondaryLabel),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.secondaryLabel)),
          ],
        ),
      ),
    );
  }

  /// Shown after the form is saved but before the fee is paid.
  Widget _buildPaymentPending() {
    final p = _pendingPayment!;
    final currency = p['currency']?.toString() ?? 'LKR';
    String money(dynamic v) => '$currency ${((v as num?) ?? 0).toStringAsFixed(2)}';
    final items = (p['feeItems'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final paid = (p['amountPaid'] as num?) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(CupertinoIcons.creditcard, size: 64, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text('Pay to Submit',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark)),
        const SizedBox(height: 8),
        Text(
          'Your application ${p['referenceNumber']} is saved. It will be sent for verification once the fee is paid.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.secondaryLabel, height: 1.4),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ...items.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Expanded(child: Text(i['feeType']?.toString() ?? 'Fee')),
                      Text(money(i['amount'])),
                    ]),
                  )),
              if (paid > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const Expanded(child: Text('Already paid')),
                    Text('- ${money(paid)}'),
                  ]),
                ),
              const Divider(),
              Row(children: [
                const Expanded(child: Text('Amount due', style: TextStyle(fontWeight: FontWeight.w700))),
                Text(money(p['amount']), style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isFinalizing ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Pay ${money(p['amount'])}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isFinalizing ? null : _finalize,
          child: _isFinalizing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('I have paid — check again'),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final msg = _submitted?['message']?.toString();
    final refNum = _submitted?['referenceNumber']?.toString() ?? 'APP-${widget.applicationId ?? widget.serviceId}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.check_mark_circled_solid, size: 72, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              _totalStages > 1
                  ? 'Stage $_currentStage Form Submitted'
                  : (_isStageMode ? 'Stage ${widget.stageNumber} Form Submitted' : 'Application Submitted'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark),
            ),
            const SizedBox(height: 8),
            Text(
              _totalStages > 1
                  ? 'Your submission for Stage $_currentStage has been queued for $_stageDepartment review.\n\nPlease wait until the verification officer approves Stage $_currentStage before advancing to Stage ${(_currentStage + 1).clamp(1, _totalStages)}.'
                  : (msg != null
                      ? '$msg\nTrack ongoing status in the Applications tab.'
                      : 'Reference: $refNum\nYou can track its progress in the Applications tab.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryLabel, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_isStageMode) {
                  Navigator.of(context).pop(true);
                } else {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
