import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/app_user.dart';

class AuthResult {
  final bool success;
  final String? token;
  final AppUser? user;
  final String? errorMessage;

  AuthResult.success(this.token, this.user) : success = true, errorMessage = null;
  AuthResult.registrationPending() : success = true, token = null, user = null, errorMessage = null;
  AuthResult.failure(this.errorMessage) : success = false, token = null, user = null;
}
class AuthService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  Future<AuthResult> register({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? phone,
    String? categorieId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Auth/register');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
          'fullName': fullName,
          'phone': phone,
          'categorieId': categorieId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Pas de token à ce stade — juste un succès d'inscription.
        return AuthResult.registrationPending();
      }
      return AuthResult.failure(_extractErrorMessage(response));
    } on TimeoutException {
      return AuthResult.failure('Le serveur met trop de temps à répondre. Réessaie.');
    } catch (e) {
      return AuthResult.failure('Impossible de contacter le serveur: $e');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Auth/login');

    try {
      debugPrint('========================================');
      debugPrint('LOGIN URL: $uri');
      debugPrint('LOGIN EMAIL: $email');

      final response = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(const Duration(seconds: 15));

      debugPrint('LOGIN STATUS: ${response.statusCode}');
      debugPrint('LOGIN BODY: ${response.body}');
      debugPrint('========================================');

      if (response.statusCode == 200) {
        return _handleAuthResponse(response.body);
      }

      return AuthResult.failure(_extractErrorMessage(response));
    } on TimeoutException {
      debugPrint('LOGIN ERROR: Request timed out');

      return AuthResult.failure(
        'Le serveur met trop de temps à répondre. Réessaie.',
      );
    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      debugPrint('LOGIN STACK TRACE: $stackTrace');

      return AuthResult.failure(
        'Impossible de contacter le serveur: $e',
      );
    }
  }

  Future<AuthResult> _handleAuthResponse(String body) async {
    final data = jsonDecode(body) as Map<String, dynamic>;

    final token = data['token'] as String;
    final user = AppUser.fromJson(
      data['user'] as Map<String, dynamic>,
    );

    await _storage.write(
      key: _tokenKey,
      value: token,
    );

    return AuthResult.success(token, user);
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded.containsKey('errors')) {
        final errors = decoded['errors'] as Map<String, dynamic>;

        return errors.values
            .expand((v) => (v as List))
            .join('\n');
      }

      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'].toString();
      }
    } catch (_) {
      // Response is not JSON, use raw body below.
    }

    return response.body.isNotEmpty
        ? response.body
        : 'Erreur ${response.statusCode}';
  }

  Future<String?> getToken() => _storage.read(
    key: _tokenKey,
  );

  Future<void> logout() => _storage.delete(
    key: _tokenKey,
  );
}