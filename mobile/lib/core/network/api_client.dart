import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: AppConfig.development,
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStorage tokenStorage,
  })  : _tokenStorage = tokenStorage,
        _dio = Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl,
            connectTimeout: config.connectTimeout,
            receiveTimeout: config.receiveTimeout,
            headers: {'Content-Type': 'application/json'},
            validateStatus: (status) => status != null && status < 500,
          ),
        ) {
    _dio.interceptors.add(
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

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<T> _unwrap<T>(
    Future<Response<Map<String, dynamic>>> call,
    T Function(Map<String, dynamic> json) parser,
  ) async {
    try {
      final response = await call;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return parser(response.data ?? {});
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

  Future<List<dynamic>> _unwrapList(
    Future<Response<dynamic>> call,
  ) async {
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

  Future<void> logout() => _tokenStorage.clear();

  Future<Map<String, dynamic>> requestOtp(String phone, {String? role}) async {
    return _unwrap(
      _dio.post<Map<String, dynamic>>(
        '/auth/otp/request',
        data: {'phone': phone, if (role != null) 'role': role},
      ),
      (json) => json,
    );
  }

  Future<UserModel> verifyOtp(String phone, String code, {String? role}) async {
    final data = await _unwrap(
      _dio.post<Map<String, dynamic>>(
        '/auth/otp/verify',
        data: {'phone': phone, 'code': code, if (role != null) 'role': role},
      ),
      (json) => json,
    );
    final token = data['accessToken'] as String?;
    if (token == null) {
      throw ApiException('No access token returned');
    }
    await _tokenStorage.saveAccessToken(token);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> getMe() async {
    return _unwrap(
      _dio.get<Map<String, dynamic>>('/users/me'),
      (json) => UserModel.fromJson(json),
    );
  }

  Future<List<PropertyModel>> searchProperties({
    int? bedrooms,
    double? minPrice,
    double? maxPrice,
  }) async {
    final data = await _unwrap(
      _dio.get<Map<String, dynamic>>(
        '/properties',
        queryParameters: {
          if (bedrooms != null) 'bedrooms': bedrooms,
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
        },
      ),
      (json) => json,
    );
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PropertyModel> getProperty(String id) async {
    return _unwrap(
      _dio.get<Map<String, dynamic>>('/properties/$id'),
      (json) => PropertyModel.fromJson(json),
    );
  }

  Future<PropertyModel> createProperty({
    required String title,
    required String description,
    required double priceEtb,
    required int bedrooms,
  }) async {
    return _unwrap(
      _dio.post<Map<String, dynamic>>(
        '/properties',
        data: {
          'title': title,
          'description': description,
          'priceEtb': priceEtb,
          'bedrooms': bedrooms,
        },
      ),
      (json) => PropertyModel.fromJson(json),
    );
  }

  Future<Map<String, dynamic>> requestViewing({
    required String propertyId,
    String? notes,
  }) async {
    return _unwrap(
      _dio.post<Map<String, dynamic>>(
        '/viewings',
        data: {'propertyId': propertyId, if (notes != null) 'notes': notes},
      ),
      (json) => json,
    );
  }

  Future<List<dynamic>> getViewings() async {
    return _unwrapList(_dio.get<dynamic>('/viewings'));
  }

  Future<List<dynamic>> getWorkers({List<String>? skills}) async {
    return _unwrapList(
      _dio.get<dynamic>(
        '/workers',
        queryParameters: {
          if (skills != null && skills.isNotEmpty) 'skills': skills.join(','),
        },
      ),
    );
  }

  Future<Map<String, dynamic>> upsertWorkerProfile({
    required List<String> skills,
    String? availability,
    double? salaryExpectation,
    String? bio,
  }) async {
    return _unwrap(
      _dio.put<Map<String, dynamic>>(
        '/workers/me',
        data: {
          'skills': skills,
          if (availability != null) 'availability': availability,
          if (salaryExpectation != null) 'salaryExpectation': salaryExpectation,
          if (bio != null) 'bio': bio,
        },
      ),
      (json) => json,
    );
  }

  Future<Map<String, dynamic>> createJob({
    required String jobType,
    required String location,
    double? salaryOffer,
    String? requirements,
  }) async {
    return _unwrap(
      _dio.post<Map<String, dynamic>>(
        '/jobs',
        data: {
          'jobType': jobType,
          'location': location,
          if (salaryOffer != null) 'salaryOffer': salaryOffer,
          if (requirements != null) 'requirements': requirements,
        },
      ),
      (json) => json,
    );
  }

  Future<List<dynamic>> getJobs() async {
    return _unwrapList(_dio.get<dynamic>('/jobs'));
  }

  Future<Map<String, dynamic>> applyToJob(String jobId, String workerId) async {
    return _unwrap(
      _dio.post<Map<String, dynamic>>('/jobs/$jobId/apply/$workerId'),
      (json) => json,
    );
  }

  Future<Map<String, dynamic>> getTrustScore(String userId) async {
    return _unwrap(
      _dio.get<Map<String, dynamic>>('/users/$userId/trust-score'),
      (json) => json,
    );
  }

  Future<List<dynamic>> getNotifications() async {
    return _unwrapList(_dio.get<dynamic>('/notifications'));
  }
}
