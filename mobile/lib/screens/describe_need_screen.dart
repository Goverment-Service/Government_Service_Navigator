import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/intake_plan_model.dart';
import 'intake_plan_result_screen.dart';


class DescribeNeedScreen extends StatefulWidget {
  const DescribeNeedScreen({super.key});

  @override
  State<DescribeNeedScreen> createState() => _DescribeNeedScreenState();
}

class _DescribeNeedScreenState extends State<DescribeNeedScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;

    // Resolves localhost safely across Web, iOS Simulator, and Android Emulator
  String get _backendUrl {
    if (kIsWeb) {
      // Safe fallback for Chrome/Web
      return 'http://localhost:5119/api/intakeagent/ask';
    } 
    
    // It is now safe to check the OS because we know we aren't on the web
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5119/api/intakeagent/ask';
    }
    
    // macOS Desktop or iOS Simulator
    return 'http://localhost:5119/api/intakeagent/ask';
  }


  Future<void> _submitNeed() async {
    final queryText = _textController.text.trim();
    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what service you need.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': queryText}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final intakePlan = IntakePlanModel.fromJson(data);

        if (!mounted) return;

               Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IntakePlanResultScreen(intakePlan: intakePlan),
          ),
        );

      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to consult agent: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Describe Your Need')),
      body: SingleChildScrollView(
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
              controller: _textController,
              maxLines: 5,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'e.g., I need to travel next month but my passport is expired...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitNeed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Find Matching Services', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
