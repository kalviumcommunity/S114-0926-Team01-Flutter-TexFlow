import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api.dart';

final authApiProvider = Provider<AuthApiService>((ref) => AuthApiService());

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final User? user;
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.status = AuthStatus.unauthenticated,
    this.errorMessage,
  });

  AuthState copyWith({User? user, AuthStatus? status, String? errorMessage}) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  bool get isSupervisor => user?.role == 'supervisor';
  bool get isManager => user?.role == 'manager';
  bool get isAdmin => user?.role == 'admin';
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final authApi = ref.read(authApiProvider);
    try {
      final authResponse = await authApi.login(
        LoginRequest(email: email, password: password),
      );
      await authApi.setToken(authResponse.token, user: authResponse.user);
      state = state.copyWith(
        user: authResponse.user,
        status: AuthStatus.authenticated,
      );
    } on UnauthorizedException {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid email or password',
      );
      rethrow;
    } on ValidationException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      rethrow;
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final authApi = ref.read(authApiProvider);
    try {
      final authResponse = await authApi.register(
        RegisterRequest(
          name: name,
          email: email,
          password: password,
          role: role,
        ),
      );
      await authApi.setToken(authResponse.token, user: authResponse.user);
      state = state.copyWith(
        user: authResponse.user,
        status: AuthStatus.authenticated,
      );
    } on BadRequestException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      rethrow;
    } on ValidationException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      rethrow;
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    final authApi = ref.read(authApiProvider);
    await authApi.clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    final authApi = ref.read(authApiProvider);
    try {
      // getCurrentUser() validates expiry, calls GET /api/auth/me for the
      // authoritative record, and clears the session on 401. A transient
      // network failure falls back to the persisted profile.
      final user = await authApi.getCurrentUser().timeout(
        const Duration(seconds: 8),
      );

      if (user != null) {
        state = AuthState(user: user, status: AuthStatus.authenticated);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      // Never leave the app stuck on the splash screen.
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}
