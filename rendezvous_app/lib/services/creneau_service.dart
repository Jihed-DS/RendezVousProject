import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/creneau.dart';

class CreneauService {
  Future<List<Creneau>> getMySlots(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Creneau/my-slots');
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger tes créneaux (${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Creneau.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({
    required String token,
    required DateTime startTime,
    required DateTime endTime,
    List<String> tags = const [],
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Creneau');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
        'tags': tags,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractError(response));
    }
  }
  Future<int> createBulk({
    required String token,
    required DateTime date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required int slotDurationMinutes,
    List<String> tags = const [],
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Creneau/bulk');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'date': date.toUtc().toIso8601String(),
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'slotDurationMinutes': slotDurationMinutes,
        'tags': tags,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractError(response));
    }

    final List<dynamic> created = jsonDecode(response.body);
    return created.length;
  }

  Future<void> delete({required String token, required String id}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Creneau/$id');
    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204) {
      throw Exception(_extractError(response));
    }
  }

  Future<List<Creneau>> getByPrestataire(String prestataireId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Creneau/by-prestataire/$prestataireId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les créneaux (${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Creneau.fromJson(e as Map<String, dynamic>)).toList();
  }
  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('errors')) {
        final errors = decoded['errors'] as Map<String, dynamic>;
        return errors.values.expand((v) => (v as List)).join('\n');
      }
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return response.body.isNotEmpty ? response.body : 'Erreur ${response.statusCode}';
  }

}