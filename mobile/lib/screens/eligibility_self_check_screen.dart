import 'package:flutter/material.dart';
import '../services/service_api_client.dart';

class EligibilitySelfCheckScreen extends StatefulWidget {
  final int serviceId;
  const EligibilitySelfCheckScreen({super.key, required this.serviceId});

  @override
  State<EligibilitySelfCheckScreen> createState() => _EligibilitySelfCheckScreenState();
}

class _EligibilitySelfCheckScreenState extends State<EligibilitySelfCheckScreen> {
  final _ageController = TextEditingController(text: '25');
  final _citizenshipController = TextEditingController(text: 'Sri Lankan');
  
  Map<String, dynamic>? result;
  bool isEvaluating = false;

  void evaluate() async {
    setState(() => isEvaluating = true);
    try {
      final res = await ServiceApiClient.evaluateEligibility(
        widget.serviceId,
        int.parse(_ageController.text),
        _citizenshipController.text,
      );
      setState(() {
        result = res;
        isEvaluating = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evaluation failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eligibility Self-Check')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Your Age'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _citizenshipController,
              decoration: const InputDecoration(labelText: 'Citizenship'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isEvaluating ? null : evaluate,
              child: isEvaluating ? const CircularProgressIndicator() : const Text('Check Eligibility'),
            ),
            const SizedBox(height: 30),
            if (result != null) ...[
              Card(
                color: result!['isEligible'] ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        result!['isEligible'] ? 'Eligible for Service!' : 'Not Eligible',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: result!['isEligible'] ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                      Text('Match: ${result!['matchPercentage']}%', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      if ((result!['missingCriteria'] as List).isNotEmpty) ...[
                        const Text('Missing / Failed Criteria:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...((result!['missingCriteria'] as List).map((crit) => Text('• $crit', style: const TextStyle(color: Colors.red)))),
                      ]
                    ],
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
