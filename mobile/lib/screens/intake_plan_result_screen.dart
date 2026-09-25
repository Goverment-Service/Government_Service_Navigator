import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/intake_plan_model.dart';

class IntakePlanResultScreen extends StatelessWidget {
  final IntakePlanModel intakePlan;

  const IntakePlanResultScreen({super.key, required this.intakePlan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matched Service Plan')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RECOMMENDED SERVICE',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    intakePlan.recommendedService,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (intakePlan.requiredDocuments.isNotEmpty) ...[
            const Text(
              'Required Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...intakePlan.requiredDocuments.map(
              (doc) => ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
                title: Text(doc),
              ),
            ),
            const Divider(height: 32),
          ],
          const Text(
            'Step-by-Step Procedure',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...intakePlan.stepByStepPlan.map(
            (step) => Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(step, style: const TextStyle(fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
