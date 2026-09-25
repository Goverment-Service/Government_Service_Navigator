import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// In-app notification (installment reminders, automatic cancellations).
class CitizenNotification {
  final int id;
  final String type; // 'InstallmentReminder', 'ApplicationCancelled'
  final String title;
  final String message;
  final int? applicationId;
  final int? installmentPlanId;
  final DateTime createdAt;
  final bool isRead;

  const CitizenNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.applicationId,
    this.installmentPlanId,
  });

  factory CitizenNotification.fromJson(Map<String, dynamic> json) => CitizenNotification(
        id: (json['id'] as num).toInt(),
        type: json['type']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        applicationId: (json['applicationId'] as num?)?.toInt(),
        installmentPlanId: (json['installmentPlanId'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        isRead: json['readAt'] != null,
      );
}

class NotificationApiService {
  final String _token;

  NotificationApiService(this._token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  /// GET /api/notifications/mine — newest first.
  Future<List<CitizenNotification>> fetchMine() async {
    final response = await http.get(Uri.parse('${AppConfig.baseUrl}/notifications/mine'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load notifications (${response.statusCode})');
    }
    return (jsonDecode(response.body) as List)
        .whereType<Map<String, dynamic>>()
        .map(CitizenNotification.fromJson)
        .toList();
  }

  /// POST /api/notifications/read-all
  Future<void> markAllRead() async {
    await http.post(Uri.parse('${AppConfig.baseUrl}/notifications/read-all'), headers: _headers);
  }
}
