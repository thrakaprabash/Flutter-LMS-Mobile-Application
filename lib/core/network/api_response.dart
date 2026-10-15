import 'api_exception.dart';

class ApiResponse<T> {
  const ApiResponse({required this.data, this.message, this.pagination});
  final T data;
  final String? message;
  final Map<String, dynamic>? pagination;
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) decode,
  ) {
    if (json['success'] == false) {
      throw ApiException(
        message: json['message']?.toString() ?? 'The request failed.',
        details: json['errors'],
      );
    }
    return ApiResponse(
      data: decode(json['data']),
      message: json['message']?.toString(),
      pagination: json['pagination'] is Map
          ? Map<String, dynamic>.from(json['pagination'] as Map)
          : null,
    );
  }
}
