import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/client_admin.dart';

class AdminClientService {
  Future<List<ClientAdminItem>> getAll(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Client');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les clients (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => ClientAdminItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}