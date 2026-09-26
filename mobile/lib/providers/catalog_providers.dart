import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/service_api_client.dart';
import 'session_provider.dart';

part 'catalog_providers.g.dart';

/// Every published government service. Kept alive: the catalog is shared by the
/// home, services and discovery screens and rarely changes during a session.
@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> services(Ref ref) async {
  final data = await ServiceApiClient.fetchServices();
  return data.whereType<Map<String, dynamic>>().toList();
}

/// Active services grouped by department (the service's `category`), departments sorted by name.
@riverpod
Future<Map<String, List<Map<String, dynamic>>>> departments(Ref ref) async {
  final services = await ref.watch(servicesProvider.future);
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final service in services) {
    if (service['status'] == 'Retired') continue;
    final category = (service['category'] as String?)?.trim();
    final key = (category == null || category.isEmpty) ? 'General' : category;
    grouped.putIfAbsent(key, () => []).add(service);
  }
  final sortedKeys = grouped.keys.toList()..sort();
  return {for (final k in sortedKeys) k: grouped[k]!};
}

@riverpod
Future<Map<String, dynamic>> serviceDetails(Ref ref, int serviceId) =>
    ServiceApiClient.fetchServiceDetails(serviceId);

/// Stage-specific details (required documents, fee schedule, department) for a given service and stage.
final serviceStageDetailsProvider = FutureProvider.family<Map<String, dynamic>, ({int serviceId, int stage})>((ref, arg) {
  return ServiceApiClient.fetchServiceStageDetails(arg.serviceId, arg.stage);
});

/// Admin-built application form for a service, or null if none is published yet.
@riverpod
Future<Map<String, dynamic>?> applicationForm(Ref ref, int serviceId) =>
    ServiceApiClient.fetchApplicationForm(serviceId, ref.watch(authTokenProvider));

typedef RequiredDocument = ({String name, String description, bool isMandatory});

/// Everything the application form screen renders, loaded together.
class ApplicationFormData {
  /// The published template, or null if the service has no form yet.
  final Map<String, dynamic>? template;
  final Map<String, dynamic>? department;
  final List<Map<String, dynamic>> fields;

  /// Catalog document requirements not already on the template as a file field.
  final List<RequiredDocument> requiredDocs;
  final bool hasFee;

  /// Multi-stage sequential workflow properties
  final int stage;
  final int totalStages;
  final List<String> workflowDepartments;
  final String? stageDescription;
  final String? stageDepartment;

  const ApplicationFormData({
    required this.template,
    required this.department,
    required this.fields,
    required this.requiredDocs,
    required this.hasFee,
    this.stage = 1,
    this.totalStages = 1,
    this.workflowDepartments = const [],
    this.stageDescription,
    this.stageDepartment,
  });
}

@riverpod
Future<ApplicationFormData> applicationFormData(Ref ref, int serviceId) async {
  final results = await Future.wait([
    ref.watch(applicationFormProvider(serviceId).future),
    // The service catalog's required documents; the form still works if this fails
    ref.watch(serviceDetailsProvider(serviceId).future).then<Map<String, dynamic>?>((d) => d, onError: (_) => null),
  ]);
  final form = results[0];
  final service = results[1];
  final template = form?['template'] as Map<String, dynamic>?;
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

  List<String> workflowDepts = [];
  final rawDepts = form?['workflowDepartments'] ?? service?['workflowDepartments'];
  if (rawDepts is List) {
    workflowDepts = rawDepts.map((e) => e.toString()).toList();
  } else if (rawDepts is String && rawDepts.isNotEmpty) {
    try {
      final decoded = jsonDecode(rawDepts);
      if (decoded is List) {
        workflowDepts = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
  }

  final totalStages = (form?['totalStages'] as num?)?.toInt() ??
                      (service?['totalStages'] as num?)?.toInt() ??
                      (workflowDepts.isNotEmpty ? workflowDepts.length : 1);
  final stage = (form?['stage'] as num?)?.toInt() ?? 
                (template?['stageOrder'] as num?)?.toInt() ?? 1;
  final stageDesc = template?['stageDescription']?.toString();
  final stageDept = template?['department']?.toString() ??
                    (workflowDepts.isNotEmpty && stage - 1 < workflowDepts.length ? workflowDepts[stage - 1] : null) ??
                    (form?['department'] as Map<String, dynamic>?)?['name']?.toString();

  return ApplicationFormData(
    template: template,
    department: form?['department'] as Map<String, dynamic>?,
    fields: fields,
    requiredDocs: requiredDocs,
    hasFee: (service?['feeSchedules'] as List? ?? []).isNotEmpty,
    stage: stage,
    totalStages: totalStages,
    workflowDepartments: workflowDepts,
    stageDescription: stageDesc,
    stageDepartment: stageDept,
  );
}
