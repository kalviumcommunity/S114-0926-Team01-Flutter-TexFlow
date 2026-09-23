import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';
import 'api_exceptions.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  Dio get dio => _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await clearToken();
        }
        return handler.next(error);
      },
    ));

    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    _dio.options.headers.remove('Authorization');
  }

  bool get hasToken => _dio.options.headers['Authorization'] != null;

  T handleResponse<T>(Response response, T Function(Map<String, dynamic>) parser) {
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw handleDioError(DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: response.data?['error'] ?? 'HTTP ${response.statusCode}',
      ));
    }
    return parser(response.data as Map<String, dynamic>);
  }

  List<T> handleListResponse<T>(
    Response response,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw handleDioError(DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: response.data?['error'] ?? 'HTTP ${response.statusCode}',
      ));
    }
    final data = response.data as List;
    return data.map((e) => parser(e as Map<String, dynamic>)).toList();
  }
}