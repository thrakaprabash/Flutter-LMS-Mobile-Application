import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
  });
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic details;
  factory ApiException.fromDio(DioException error) {
    final body = error.response?.data;
    final map = body is Map ? body : const {};
    final message = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'The request timed out. Please try again.',
      DioExceptionType.connectionError =>
        'Cannot connect to the server. Check your connection and try again.',
      DioExceptionType.cancel => 'The request was cancelled.',
      DioExceptionType.badCertificate =>
        'The server connection could not be verified.',
      _ =>
        map['message'] is String
            ? map['message'] as String
            : 'The request failed. Please try again.',
    };
    return ApiException(
      message: message,
      statusCode: error.response?.statusCode,
      errorCode: map['errorCode']?.toString(),
      details: map['errors'] ?? map['details'],
    );
  }
  @override
  String toString() => message;
}
