class TemplateFormField {
  final String id;
  final String label;
  final String type; // text, textarea, number, date, select, multiselect, file, table, heading, paragraph
  final String? options; // comma separated, for select/multiselect
  final bool isRequired;
  final int orderIndex;

  TemplateFormField({
    required this.id,
    required this.label,
    required this.type,
    this.options,
    required this.isRequired,
    required this.orderIndex,
  });

  List<String> get optionList =>
      (options ?? '').split(',').map((o) => o.trim()).where((o) => o.isNotEmpty).toList();

  factory TemplateFormField.fromJson(Map<String, dynamic> json) => TemplateFormField(
        id: json['id'].toString(),
        label: json['label'] as String? ?? '',
        type: json['type'] as String? ?? 'text',
        options: json['options'] as String?,
        isRequired: json['isRequired'] as bool? ?? false,
        orderIndex: json['orderIndex'] as int? ?? 0,
      );
}

class ApplicationTemplate {
  final String id;
  final String formName;
  final String? subTitle;
  final List<TemplateFormField> fields;

  ApplicationTemplate({required this.id, required this.formName, this.subTitle, required this.fields});

  factory ApplicationTemplate.fromJson(Map<String, dynamic> json) {
    final rawFields = (json['fields'] as List<dynamic>? ?? [])
        .map((f) => TemplateFormField.fromJson(f as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return ApplicationTemplate(
      id: json['id'].toString(),
      formName: json['formName'] as String? ?? '',
      subTitle: json['subTitle'] as String?,
      fields: rawFields,
    );
  }
}

class ServiceApplication {
  final int id;
  final String applicationReference;
  final int serviceProcedureId;
  final String serviceName;
  final String category;
  final String department;
  final String status; // Pending, Approved, Rejected, Revised
  final DateTime submittedAt;
  final DateTime? decisionAt;
  final String? decisionNotes;
  final Map<String, String> answers;

  ServiceApplication({
    required this.id,
    required this.applicationReference,
    required this.serviceProcedureId,
    required this.serviceName,
    required this.category,
    required this.department,
    required this.status,
    required this.submittedAt,
    this.decisionAt,
    this.decisionNotes,
    this.answers = const {},
  });

  factory ServiceApplication.fromJson(Map<String, dynamic> json) => ServiceApplication(
        id: json['id'] as int,
        applicationReference: json['applicationReference'] as String,
        serviceProcedureId: json['serviceProcedureId'] as int,
        serviceName: json['serviceName'] as String? ?? '',
        category: json['category'] as String? ?? 'Other',
        department: (json['department'] as String?)?.trim().isNotEmpty == true
            ? json['department'] as String
            : (json['category'] as String? ?? 'Other'),
        status: json['status'] as String? ?? 'Pending',
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        decisionAt: json['decisionAt'] != null ? DateTime.parse(json['decisionAt'] as String) : null,
        decisionNotes: json['decisionNotes'] as String?,
        answers: (json['answers'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v.toString())),
      );
}
