import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';
import '../config/constants.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<User> login(String email, String password) async {
    final response = await _api.dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    await _api.setToken(response.data['token']);
    return User.fromJson(response.data['user']);
  }

  Future<void> logout() async {
    await _api.clearToken();
  }

  Future<User?> getCurrentUser() async {
    final token = await _api.getToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return User(
        id: payload['id'] ?? '',
        name: payload['name'] ?? '',
        email: payload['email'] ?? '',
        role: payload['role'] ?? 'supervisor',
      );
    } catch (_) {
      return null;
    }
  }
}
