import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/catalog_providers.dart';
import '../providers/session_provider.dart';
import 'eligibility_self_check_screen.dart';
import 'application_form_screen.dart';

class ProcedureDetailScreen extends ConsumerWidget {
  final int serviceId;
  const ProcedureDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(serviceDetailsProvider(serviceId));
    final isSignedIn = ref.watch(sessionProvider.select((s) => s.isSignedIn));

    if (details.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final serviceDetails = details.value;
    if (serviceDetails == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Failed to load details')),
      );
    }

    final docs = serviceDetails['documentRequirements'] ?? [];
    final fees = serviceDetails['feeSchedules'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(serviceDetails['name'])),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Service ID: ${serviceDetails['serviceId']}',
            style: const TextStyle(color: AppColors.secondaryLabel),
          ),
          const SizedBox(height: 10),
          const Text(
            'Required Documents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (docs.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'You will upload these in the application form after tapping Apply Now.',
                style: TextStyle(color: AppColors.secondaryLabel, fontSize: 13),
              ),
            ),
          ...docs.map<Widget>(
            (doc) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(doc['documentName']),
              subtitle: (doc['description'] ?? '').toString().isEmpty ? null : Text(doc['description']),
              trailing: Text(
                doc['isMandatory'] == true ? 'Required' : 'Optional',
                style: TextStyle(
                  fontSize: 12,
                  color: doc['isMandatory'] == true ? AppColors.danger : AppColors.secondaryLabel,
                ),
              ),
            ),
          ),
          const Divider(height: 30),
          const Text(
            'Fee Schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ...fees.map<Widget>(
            (fee) => ListTile(
              title: Text(fee['feeType']),
              trailing: Text('LKR ${fee['amount']}'),
            ),
          ),
          const SizedBox(height: 30),
          if (isSignedIn) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_document),
              label: const Text('Apply Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApplicationFormScreen(
                      serviceId: serviceId,
                      serviceName:
                          serviceDetails['name'] ?? 'Government Service',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Run Eligibility Self-Check'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EligibilitySelfCheckScreen(
                    serviceId: serviceId,
                    serviceName:
                        serviceDetails['name'] ?? 'Government Service',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
