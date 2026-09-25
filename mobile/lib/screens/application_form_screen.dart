import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import '../services/service_api_client.dart';

/// Renders the admin-built application template as a paper-style government form
/// (matching the web Template Builder canvas) and submits the citizen's answers.
class ApplicationFormScreen extends StatefulWidget {
  final int serviceId;
  final String serviceName;
  final String token;

  const ApplicationFormScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.token,
  });

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
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

  Map<String, dynamic>? _template;
  List<Map<String, dynamic>> _fields = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;
  Map<String, dynamic>? _submitted;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectValues = {};
  final Map<String, Set<String>> _multiValues = {};

  /// File fields: label -> uploaded document (id from the backend), plus labels still uploading.
  final Map<String, ({String id, String fileName})> _documents = {};
  final Set<String> _uploading = {};

  /// The service's required documents from the catalog, each uploaded like a file field.
  List<({String name, String description, bool isMandatory})> _requiredDocs = [];

  /// Table fields: label -> rows -> one controller per column.
  final Map<String, List<List<TextEditingController>>> _tableRows = {};

  @override
  void initState() {
    super.initState();
    _loadForm();
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

  Future<void> _loadForm() async {
    try {
      final results = await Future.wait([
        ServiceApiClient.fetchApplicationForm(widget.serviceId, widget.token),
        // The service catalog's required documents; the form still works if this fails
        ServiceApiClient.fetchServiceDetails(widget.serviceId).then<Map<String, dynamic>?>((d) => d, onError: (_) => null),
      ]);
      final form = results[0];
      final service = results[1];
      final template = form?['template'] as Map<String, dynamic>?;
      final department = form?['department'] as Map<String, dynamic>?;
      _controllerFor(_presentedByKey).text = department?['name']?.toString() ?? '';
      _controllerFor(_emailKey).text = department?['email']?.toString() ?? '';
      final fields = (template?['fields'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList()
        ..sort((a, b) => ((a['orderIndex'] ?? 0) as int).compareTo((b['orderIndex'] ?? 0) as int));

      // Skip requirements the admin already added to the template as a file field
      final fileLabels = fields.where((f) => f['type'] == 'file').map((f) => f['label']?.toString()).toSet();
      final requiredDocs = (service?['documentRequirements'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((d) => (
                name: d['documentName']?.toString() ?? '',
                description: d['description']?.toString() ?? '',
                isMandatory: d['isMandatory'] == true,
              ))
          .where((d) => d.name.isNotEmpty && !fileLabels.contains(d.name))
          .toList();

      if (!mounted) return;
      setState(() {
        _template = template;
        _fields = fields;
        _requiredDocs = requiredDocs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load the application form.';
        _isLoading = false;
      });
    }
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
      final result = await ServiceApiClient.submitApplication(
        serviceId: widget.serviceId,
        templateId: _template?['id']?.toString(),
        answers: _collectAnswers(),
        documents: {for (final e in _documents.entries) e.key: e.value.id},
        token: widget.token,
      );
      if (!mounted) return;
      setState(() => _submitted = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: DefaultTextStyle(
              style: const TextStyle(color: _ink, fontSize: 14, height: 1.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
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
                  : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
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
          margin: const EdgeInsets.only(top: 16, bottom: 12),
          padding: const EdgeInsets.only(bottom: 4),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _ink, width: 2))),
          child: const Text('REQUIRED DOCUMENTS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
        token: widget.token,
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

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.check_mark_circled_solid, size: 72, color: AppColors.success),
            const SizedBox(height: 16),
            const Text('Application Submitted',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.dark)),
            const SizedBox(height: 8),
            Text(
              'Reference: ${_submitted!['referenceNumber']}\n'
              'You can track its progress in the Applications tab.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryLabel, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
