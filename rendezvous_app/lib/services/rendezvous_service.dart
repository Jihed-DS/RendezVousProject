import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/rendez_vous.dart';
class RendezVousService {
  Future<void> create({
    required String token,
    required String creneauId,
    String? notes,
    List<String>? selectedTags,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/RendezVous');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'creneauId': creneauId,
        'notes': notes,
        'selectedTags': selectedTags,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractError(response));
    }
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
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
  Future<List<RendezVousItem>> getMyBookings(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/RendezVous/my-bookings');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger tes rendez-vous (${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => RendezVousItem.fromJson(e as Map<String, dynamic>)).toList();
  }
  Future<void> reschedule({
    required String token,
    required String rendezVousId,
    required String newCreneauId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/RendezVous/reschedule/$rendezVousId');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'newCreneauId': newCreneauId}),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
  }
  Future<void> confirm({required String token, required String id}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/RendezVous/confirm/$id');
    final response = await http.post(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }

  Future<void> deny({required String token, required String id}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/RendezVous/deny/$id');
    final response = await http.post(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }
  Future<void> complete({required String token, required String id}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/RendezVous/complete/$id');
    final response = await http.post(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }
  Future<void> cancel({required String token, required String id}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/RendezVous/cancel/$id');
    final response = await http.post(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) throw Exception(_extractError(response));
  }
}