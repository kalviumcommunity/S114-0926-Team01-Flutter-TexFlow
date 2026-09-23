import 'package:dio/dio.dart';

abstract class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  const ApiException(this.statusCode, this.message, [this.details]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class BadRequestException extends ApiException {
  const BadRequestException(String message, [Map<String, dynamic>? details]) : super(400, message, details);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Unauthorized', Map<String, dynamic>? details]) : super(401, message, details);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([String message = 'Insufficient permissions', Map<String, dynamic>? details]) : super(403, message, details);
}

class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Resource not found', Map<String, dynamic>? details]) : super(404, message, details);
}

class ValidationException extends ApiException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException(
    String message, {
    Map<String, dynamic>? details,
    this.fieldErrors,
  }) : super(422, message, details);
}

class ServerException extends ApiException {
  const ServerException([String message = 'Internal server error', Map<String, dynamic>? details]) : super(500, message, details);
}

class NetworkException extends ApiException {
  const NetworkException([String message = 'Network error', Map<String, dynamic>? details]) : super(0, message, details);
}

class TimeoutException extends ApiException {
  const TimeoutException([String message = 'Request timeout', Map<String, dynamic>? details]) : super(408, message, details);
}

class UnknownApiException extends ApiException {
  const UnknownApiException(String message, [Map<String, dynamic>? details]) : super(-1, message, details);
}

ApiException handleDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return TimeoutException('Request timeout: ${error.message}');
    case DioExceptionType.connectionError:
      return NetworkException('Connection failed: ${error.message}');
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode ?? 0;
      final data = error.response?.data;
      final message = data is Map ? data['error']?.toString() ?? 'Unknown error' : 'Unknown error';
      final details = data is Map<String, dynamic> ? data : (data is Map ? Map<String, dynamic>.from(data) : null);

      switch (statusCode) {
        case 400:
          return BadRequestException(message, details);
        case 401:
          return UnauthorizedException(message, details);
        case 403:
          return ForbiddenException(message, details);
        case 404:
          return NotFoundException(message, details);
        case 422:
          Map<String, List<String>>? fieldErrors;
          if (data is Map && data['errors'] is Map) {
            fieldErrors = (data['errors'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()),
            );
          }
          return ValidationException(message, details: details, fieldErrors: fieldErrors);
        case 500:
          return ServerException(message, details);
        default:
          return UnknownApiException('HTTP $statusCode: $message', details);
      }
    case DioExceptionType.cancel:
      return NetworkException('Request cancelled');
    case DioExceptionType.unknown:
      return NetworkException('Network error: ${error.message}');
    default:
      return UnknownApiException('Unknown error: ${error.message}');
  }
}