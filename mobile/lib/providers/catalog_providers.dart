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

  const ApplicationFormData({
    required this.template,
    required this.department,
    required this.fields,
    required this.requiredDocs,
    required this.hasFee,
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

  return ApplicationFormData(
    template: template,
    department: form?['department'] as Map<String, dynamic>?,
    fields: fields,
    requiredDocs: requiredDocs,
    hasFee: (service?['feeSchedules'] as List? ?? []).isNotEmpty,
  );
}
