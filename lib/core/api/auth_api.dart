import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../models/auth.dart';
import '../../models/user.dart';

class AuthApiService {
  final ApiClient _client = ApiClient();

  AuthApiService() {
    _client.initialize();
  }

  /// POST /api/auth/login
  /// Request: { email: string, password: string }
  /// Response: { user: User, token: string }
  /// Errors: 400 (validation), 401 (invalid credentials), 500
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _client.dio.post(
        '/auth/login',
        data: request.toJson(),
      );
      return _client.handleResponse(response, AuthResponse.fromJson);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// POST /api/auth/register
  /// Request: { name: string, email: string, password: string, role?: string }
  /// Response: { user: User, token: string }
  /// Errors: 400 (validation), 409 (email exists), 500
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _client.dio.post(
        '/auth/register',
        data: request.toJson(),
      );
      return _client.handleResponse(response, AuthResponse.fromJson);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Get current user from stored JWT token
  /// Parses the JWT payload to extract user info
  Future<User?> getCurrentUser() async {
    final token = await _client.getToken();
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> setToken(String token) async {
    await _client.setToken(token);
  }

  Future<void> clearToken() async {
    await _client.clearToken();
  }

  Future<String?> getToken() async {
    return await _client.getToken();
  }

  bool get isAuthenticated => _client.hasToken;
}