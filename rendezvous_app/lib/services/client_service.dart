import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';

class ClientService {
  Future<Map<String, dynamic>?> getMyProfile(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Client/me');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<String> uploadPhoto({required String token, required XFile photoFile}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Client/me/photo');
    final bytes = await photoFile.readAsBytes();
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('photo', bytes, filename: photoFile.name.isNotEmpty ? photoFile.name : 'photo.jpg'));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) throw Exception('Erreur ${response.statusCode}');
    return (jsonDecode(response.body) as Map<String, dynamic>)['photoUrl'] as String;
  }
}