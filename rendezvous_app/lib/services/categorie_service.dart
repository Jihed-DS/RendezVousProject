import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/categorie.dart';

class CategorieService {
  Future<List<Categorie>> getAll() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Categories');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les catégories (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Categorie.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({required String token, required String name, String? description}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Categories');
    final response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractError(response));
    }
  }

  Future<void> update({
    required String token,
    required String id,
    required String name,
    String? description,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Categories/$id');
    final response = await http.put(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (response.statusCode != 204) {
      throw Exception(_extractError(response));
    }
  }

  Future<void> delete({required String token, required String id}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Categories/$id');
    final response = await http.delete(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 204) {
      throw Exception(_extractError(response));
    }
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is String) return decoded;
      if (decoded is Map && decoded.containsKey('message')) return decoded['message'].toString();
      if (decoded is Map && decoded.containsKey('errors')) {
        final errors = decoded['errors'] as Map<String, dynamic>;
        return errors.values.expand((v) => (v as List)).join('\n');
      }
    } catch (_) {}
    return response.body.isNotEmpty ? response.body : 'Erreur ${response.statusCode}';
  }
}