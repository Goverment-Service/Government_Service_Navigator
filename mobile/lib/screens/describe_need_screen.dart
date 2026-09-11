import 'package:flutter/material.dart';
import 'service_discovery_screen.dart';

class DescribeNeedScreen extends StatelessWidget {
  const DescribeNeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Describe Your Need')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tell us what you need help with, and our navigator will match you to the right procedure.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'e.g., I need to register a new vehicle or get a police report...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to service discovery or a matching screen result
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServiceDiscoveryScreen()),
                );
              },
              child: const Text('Find Matching Services'),
            ),
          ],
        ),
      ),
    );
  }
}
