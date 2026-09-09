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
}
