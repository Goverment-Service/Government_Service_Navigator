import 'package:flutter/material.dart';
import '../models/eligibility_agent_model.dart';
import '../services/eligibility_agent_service.dart';

class EligibilitySelfCheckScreen extends StatefulWidget {
  final int serviceId;
  final String serviceName;

  const EligibilitySelfCheckScreen({
    super.key,
    required this.serviceId,
    this.serviceName = 'Passport Renewal & Application',
  });

  @override
  State<EligibilitySelfCheckScreen> createState() => _EligibilitySelfCheckScreenState();
}

class _EligibilitySelfCheckScreenState extends State<EligibilitySelfCheckScreen> {
  late TextEditingController _serviceNameController;
  final _ageController = TextEditingController(text: '25');
  final _citizenshipController = TextEditingController(text: 'Sri Lankan');
  final _incomeController = TextEditingController(text: '500000');
  final _employmentController = TextEditingController(text: 'Employed');
  final _providedDocsController = TextEditingController(text: 'National Identity Card (NIC)');

  EligibilityAgentResponse? agentResult;
  bool isEvaluating = false;

  @override
  void initState() {
    super.initState();
    _serviceNameController = TextEditingController(text: widget.serviceName);
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _ageController.dispose();
    _citizenshipController.dispose();
    _incomeController.dispose();
    _employmentController.dispose();
    _providedDocsController.dispose();
    super.dispose();
  }

  void evaluate() async {
    setState(() => isEvaluating = true);
    try {
      final providedList = _providedDocsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final res = await EligibilityAgentService.evaluateEligibility(
        serviceName: _serviceNameController.text.trim().isNotEmpty
            ? _serviceNameController.text.trim()
            : widget.serviceName,
        serviceId: widget.serviceId,
        age: int.tryParse(_ageController.text) ?? 25,
        citizenshipStatus: _citizenshipController.text,
        annualIncome: double.tryParse(_incomeController.text) ?? 0,
        employmentStatus: _employmentController.text,
        providedDocuments: providedList,
      );

      setState(() {
        agentResult = res;
        isEvaluating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isEvaluating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agent evaluation failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent 2: Eligibility & Document Check')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _serviceNameController,
              decoration: const InputDecoration(
                labelText: 'Target Service Name',
                hintText: 'e.g. Passport Renewal, Small Business Registration',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.stars),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Applicant Age', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _citizenshipController,
              decoration: const InputDecoration(labelText: 'Citizenship Status', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _employmentController,
              decoration: const InputDecoration(labelText: 'Employment Status', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _providedDocsController,
              decoration: const InputDecoration(
                labelText: 'Provided Documents (comma-separated)',
                hintText: 'e.g. NIC, Birth Certificate',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isEvaluating ? null : evaluate,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: isEvaluating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Consult Agent 2 RAG Engine', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            if (agentResult != null) ...[
              Card(
                elevation: 4,
                color: agentResult!.isEligible ? Colors.green[50] : Colors.red[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              agentResult!.isEligible ? 'Eligible for Service' : 'Requirements Not Met',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: agentResult!.isEligible ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              'Match: ${agentResult!.matchPercentage}%',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: agentResult!.matchPercentage >= 70 ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      if (agentResult!.reasoning.isNotEmpty) ...[
                        const Text('AI Reasoning:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(agentResult!.reasoning, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                      ],
                      if (agentResult!.missingCriteria.isNotEmpty) ...[
                        const Text('Missing / Failed Criteria:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        const SizedBox(height: 4),
                        ...agentResult!.missingCriteria.map((c) => Text('• $c', style: const TextStyle(color: Colors.red))),
                        const SizedBox(height: 12),
                      ],
                      if (agentResult!.missingDocuments.isNotEmpty) ...[
                        const Text('Missing Required Documents:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        const SizedBox(height: 4),
                        ...agentResult!.missingDocuments.map((d) => Text('• $d', style: const TextStyle(color: Colors.deepOrange))),
                      ] else ...[
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 6),
                            Text('All required documents provided!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
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
