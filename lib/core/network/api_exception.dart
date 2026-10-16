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
    var message = switch (error.type) {
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
    final status = error.response?.statusCode;
    if (status != null && status >= 500) {
      message =
          'The server could not complete the request. Please try again later.';
    } else if (status == 422 && map['details'] is List) {
      final fields = (map['details'] as List)
          .whereType<Map>()
          .map((item) => item['field']?.toString().split('.').last)
          .whereType<String>()
          .map(
            (field) => field.replaceAllMapped(
              RegExp('[A-Z]'),
              (m) => ' ${m[0]!.toLowerCase()}',
            ),
          )
          .toSet();
      if (fields.isNotEmpty) message = 'Please check: ${fields.join(', ')}.';
    }
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
