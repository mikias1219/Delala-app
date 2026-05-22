import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

final httpClientProvider = Provider<HttpClient>((ref) {
  return HttpClient(
    config: AppConfig.development,
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// Shared HTTP layer — feature APIs use this, do not duplicate Dio setup.
class HttpClient {
  HttpClient({
    required AppConfig config,
    required TokenStorage tokenStorage,
  })  : _tokenStorage = tokenStorage,
        dio = Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl,
            connectTimeout: config.connectTimeout,
            receiveTimeout: config.receiveTimeout,
            headers: {'Content-Type': 'application/json'},
            validateStatus: (status) => status != null && status < 500,
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final TokenStorage _tokenStorage;

  Future<void> clearToken() => _tokenStorage.clear();

  Future<void> saveToken(String token) => _tokenStorage.saveAccessToken(token);

  Future<T> postJson<T>(
    String path, {
    Map<String, dynamic>? data,
    required T Function(Map<String, dynamic> json) parse,
  }) =>
      _unwrap(dio.post<Map<String, dynamic>>(path, data: data), parse);

  Future<T> getJson<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(Map<String, dynamic> json) parse,
  }) =>
      _unwrap(dio.get<Map<String, dynamic>>(path, queryParameters: query), parse);

  Future<T> putJson<T>(
    String path, {
    Map<String, dynamic>? data,
    required T Function(Map<String, dynamic> json) parse,
  }) =>
      _unwrap(dio.put<Map<String, dynamic>>(path, data: data), parse);

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query}) =>
      _unwrapList(dio.get<dynamic>(path, queryParameters: query));

  Future<T> _unwrap<T>(
    Future<Response<Map<String, dynamic>>> call,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    try {
      final response = await call;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return parse(response.data ?? {});
      }
      throw ApiException.fromDio(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<dynamic>> _unwrapList(Future<Response<dynamic>> call) async {
    try {
      final response = await call;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data as List<dynamic>? ?? [];
      }
      throw ApiException.fromDio(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
