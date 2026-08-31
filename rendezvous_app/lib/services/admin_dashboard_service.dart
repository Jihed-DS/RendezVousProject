import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/admin_dashboard.dart';

class AdminDashboardService {
  Future<AdminDashboard> get(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/AdminDashboard');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger le dashboard (${response.statusCode})');
    }
    return AdminDashboard.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}