import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'];
      if (msg is List) {
        return ApiException(msg.join(', '), statusCode: error.response?.statusCode);
      }
      return ApiException(msg.toString(), statusCode: error.response?.statusCode);
    }
    return ApiException(error.message ?? 'Network error', statusCode: error.response?.statusCode);
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
