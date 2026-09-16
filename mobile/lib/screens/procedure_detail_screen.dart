import 'package:flutter/material.dart';
import '../services/service_api_client.dart';
import 'eligibility_self_check_screen.dart';
import 'applications/application_submit_screen.dart';

class ProcedureDetailScreen extends StatefulWidget {
  final int serviceId;
  const ProcedureDetailScreen({super.key, required this.serviceId});

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
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    if (serviceDetails == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Failed to load details')));
    }

    final docs = serviceDetails!['documentRequirements'] ?? [];
    final fees = serviceDetails!['feeSchedules'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(serviceDetails!['name'])),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Service ID: ${serviceDetails!['serviceId']}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          const Text('Required Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...docs.map<Widget>((doc) => CheckboxListTile(
                title: Text(doc['documentName']),
                subtitle: Text(doc['description'] ?? ''),
                value: doc['isMandatory'],
                onChanged: (val) {},
              )),
          const Divider(height: 30),
          const Text('Fee Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...fees.map<Widget>((fee) => ListTile(
                title: Text(fee['feeType']),
                trailing: Text('LKR ${fee['amount']}'),
              )),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Run Eligibility Self-Check'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EligibilitySelfCheckScreen(serviceId: widget.serviceId),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.send_outlined),
            label: const Text('Apply for this Service'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApplicationSubmitScreen(
                    serviceId: widget.serviceId,
                    serviceName: serviceDetails!['name'] as String,
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
