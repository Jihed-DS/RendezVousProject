import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notification_item.dart';

class NotificationService {
  Future<List<NotificationItem>> getMyNotifications(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Notification/my-notifications');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les notifications (${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
  }
  Future<int> getUnreadCount(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Notification/unread-count');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) return 0;
    return int.tryParse(response.body) ?? 0;
  }
  Future<void> markAsRead({required String token, required String id}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Notification/mark-as-read/$id');
    final response = await http.put(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode != 204) {
      throw Exception('Impossible de marquer comme lu (${response.statusCode})');
    }

  }
}