import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _user != null;

  // Appelé au démarrage de l'app pour restaurer une session existante.
  Future<void> tryAutoLogin() async {
    final storedToken = await _authService.getToken();
    if (storedToken == null) return;

    if (JwtDecoder.isExpired(storedToken)) {
      await _authService.logout();
      return;
    }

    _token = storedToken;
    _user = _userFromToken(storedToken);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    final result = await _authService.login(email: email, password: password);
    _setLoading(false);

    if (result.success) {
      _token = result.token;
      _user = result.user;
      _errorMessage = null;
      notifyListeners();
      return true;
    }
    _errorMessage = result.errorMessage;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? phone,
    String? categorieId,
  }) async {
    _setLoading(true);
    final result = await _authService.register(
      email: email,
      password: password,
      role: role,
      fullName: fullName,
      phone: phone,
      categorieId: categorieId,
    );
    _setLoading(false);

        _errorMessage = result.success ? null : result.errorMessage;
        notifyListeners();
        return result.success;
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Reconstruit un AppUser minimal depuis les claims du token stocké,
  // en gérant les deux formats de clés (courtes et URI longues — ton
  // backend utilise ClaimTypes.* qui sérialise en URI complètes).
  AppUser _userFromToken(String token) {
    final claims = JwtDecoder.decode(token);
    final id = claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
        ?? claims['nameidentifier'] ?? claims['sub'] ?? '';
    final email = claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']
        ?? claims['email'] ?? '';
    final role = claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']
        ?? claims['role'] ?? '';
    final fullName = claims['FullName'] as String?;

    return AppUser(id: id, email: email, role: role, fullName: fullName);
  }
}