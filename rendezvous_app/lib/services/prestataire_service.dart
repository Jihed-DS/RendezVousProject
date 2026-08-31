import 'dart:convert';
import '../config/api_config.dart';
import '../models/prestataire.dart';
import '../models/categorie.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
class PrestataireService {
  Future<List<Prestataire>> getAll() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Prestataire');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les prestataires (${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Prestataire.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Categorie>> getCategories() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Categories');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Impossible de charger les catégories (${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Categorie.fromJson(e as Map<String, dynamic>)).toList();
  }
  Future<Prestataire?> getMyProfile(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Prestataire/me');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Impossible de charger ton profil (${response.statusCode})');
    }

    return Prestataire.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  Future<String> uploadPhoto({required String token, required XFile photoFile}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Prestataire/me/photo');
    final bytes = await photoFile.readAsBytes();
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
        ..files.add(http.MultipartFile.fromBytes(
            'photo', bytes,
            filename: photoFile.name.isNotEmpty ? photoFile.name : 'photo.jpg',
          ));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['photoUrl'] as String;
  }
  Future<void> createProfile({
    required String token,
    required String categorieId,
    String? bio,
    String? city,
    String? photoUrl,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Prestataire');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'categorieId': categorieId,
        'bio': bio,
        'photoUrl': photoUrl,
        'city':city
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractError(response));
    }
  }
  Future<void> updateProfile({
    required String token,
    required String id,
    String? bio,
    String? photoUrl,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Prestataire/$id');
    final response = await http.put(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'bio': bio, 'photoUrl': photoUrl}),
    );
    if (response.statusCode != 204) throw Exception(_extractError(response));
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