import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chat_message.dart';

class ChatService {
  Future<String> sendMessage({
    required String token,
    required List<ChatMessage> history,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Chat/message');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'messages': history.map((m) => m.toJson()).toList(),
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['reply'] as String;
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is String) return decoded;
      if (decoded is Map && decoded.containsKey('message')) return decoded['message'].toString();
      if (decoded is Map && decoded.containsKey('error')) return decoded['error'].toString();
} catch (_) {}
    // ASP.NET Core renvoie parfois du texte brut (pas du JSON) pour les
    // StatusCode(code, "string") — on l'affiche tel quel pour diagnostiquer.
    return response.body.isNotEmpty
        ? 'Erreur (${response.statusCode}): ${response.body}'
        : 'Erreur ${response.statusCode} sans détail.';}
}