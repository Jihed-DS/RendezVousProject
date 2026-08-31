import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/avis.dart';
import '../models/avis_summary.dart';
class AvisService {
  Future<List<Avis>> getMyReviews(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Avis/my-reviews');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger tes avis (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Avis.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Avis>> getByPrestataire(String prestataireId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Avis/prestataire/$prestataireId');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les avis (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Avis.fromJson(e as Map<String, dynamic>)).toList();
  }
  Future<AvisSummary> getSummary(String prestataireId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Avis/summary/$prestataireId');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger le résumé des avis (${response.statusCode})');
    }
    return AvisSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  Future<void> create({
    required String token,
    required String prestataireId,
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Avis');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'prestataireId': prestataireId,
        'appointmentId': appointmentId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractError(response));
    }
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is String) return decoded;
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'].toString();
      }
      if (decoded is Map && decoded.containsKey('errors')) {
        final errors = decoded['errors'] as Map<String, dynamic>;
        return errors.values.expand((v) => (v as List)).join('\n');
      }
    } catch (_) {}
    return response.body.isNotEmpty ? response.body : 'Erreur ${response.statusCode}';
  }
}