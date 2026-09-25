import 'package:flutter/material.dart';
import '../services/service_api_client.dart';
import 'eligibility_self_check_screen.dart';
import 'application_form_screen.dart';

class ProcedureDetailScreen extends StatefulWidget {
  final int serviceId;
  final String? token;
  const ProcedureDetailScreen({super.key, required this.serviceId, this.token});

  @override
  State<ProcedureDetailScreen> createState() => _ProcedureDetailScreenState();
}

class _ProcedureDetailScreenState extends State<ProcedureDetailScreen> {
  Map<String, dynamic>? serviceDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  void fetchDetails() async {
    try {
      final data = await ServiceApiClient.fetchServiceDetails(widget.serviceId);
      setState(() {
        serviceDetails = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (serviceDetails == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Failed to load details')),
      );
    }

    final docs = serviceDetails!['documentRequirements'] ?? [];
    final fees = serviceDetails!['feeSchedules'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(serviceDetails!['name'])),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Service ID: ${serviceDetails!['serviceId']}',
            style: const TextStyle(color: Colors.grey),
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
                style: TextStyle(color: Colors.grey, fontSize: 13),
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
                  color: doc['isMandatory'] == true ? Colors.red.shade700 : Colors.grey,
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
          if (widget.token != null) ...[
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
                      serviceId: widget.serviceId,
                      serviceName:
                          serviceDetails!['name'] ?? 'Government Service',
                      token: widget.token!,
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
                    serviceId: widget.serviceId,
                    serviceName:
                        serviceDetails!['name'] ?? 'Government Service',
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
