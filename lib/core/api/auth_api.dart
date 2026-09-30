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
      return await _client.handleResponse(response, AuthResponse.fromJson);
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
      return await _client.handleResponse(response, AuthResponse.fromJson);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Restores the current user from the backend.
  ///
  /// The JWT only carries `id`/`email`/`role` (no `name`), so decoding it is
  /// not enough to build a profile. Instead:
  ///  * reject the session locally if the token is already expired;
  ///  * ask `GET /api/auth/me` for the authoritative user record;
  ///  * on 401 clear the session and return null;
  ///  * on a transient/network failure fall back to the persisted user record.
  Future<User?> getCurrentUser() async {
    final token = await _client.getToken();
    if (token == null) return null;

    if (_isTokenExpired(token)) {
      await _client.clearSession();
      return null;
    }

    try {
      final response = await _client.dio.get('/auth/me');
      final user = _client.handleResponse(response, User.fromJson);
      await _client.saveUser(user.toJson());
      return user;
    } on UnauthorizedException {
      await _client.clearSession();
      return null;
    } catch (_) {
      // Backend unreachable (offline) - keep the session if the token is still
      // within its validity window, using the last persisted profile.
      return getStoredUser();
    }
  }

  /// Reads the last persisted user record without any network access.
  Future<User?> getStoredUser() async {
    final json = await _client.readUser();
    if (json == null) return null;
    try {
      return User.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> setToken(String token, {User? user}) async {
    await _client.setToken(token);
    if (user != null) {
      await _client.saveUser(user.toJson());
    }
  }

  Future<void> clearToken() async {
    await _client.clearSession();
  }

  Future<String?> getToken() async {
    return _client.getToken();
  }

  bool get isAuthenticated => _client.hasToken;

  /// Returns true when the JWT `exp` claim is in the past.
  ///
  /// Malformed/absent claims are treated as "not expired" so a parsing quirk
  /// can never lock a user out of a valid session.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload is Map ? payload['exp'] : null;
      if (exp is! int) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        exp * 1000,
        isUtc: true,
      );
      return DateTime.now().toUtc().isAfter(expiry);
    } catch (_) {
      return false;
    }
  }
}
