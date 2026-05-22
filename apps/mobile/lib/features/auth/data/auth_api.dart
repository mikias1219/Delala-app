import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/http_client.dart';

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(
    ref.watch(httpClientProvider),
    ref.read(authSessionProvider),
  ),
);

class AuthApi {
  AuthApi(this._http, this._session);

  final HttpClient _http;
  final AuthSession _session;

  Future<Map<String, dynamic>> requestOtp(
    String phone, {
    String? role,
    bool isRegistration = false,
  }) =>
      _http.postJson(
        '/auth/otp/request',
        data: {
          'phone': phone,
          if (role != null) 'role': role,
          'isRegistration': isRegistration,
        },
        parse: (json) => json,
      );

  Future<UserModel> verifyOtp(
    String phone,
    String code, {
    String? role,
  }) async {
    final data = await _http.postJson(
      '/auth/otp/verify',
      data: {
        'phone': phone,
        'code': code,
        if (role != null) 'role': role,
      },
      parse: (json) => json,
    );
    final token = data['accessToken'] as String?;
    if (token == null) throw ApiException('No access token returned');
    await _http.saveToken(token);
    _session.markLoggedIn();
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> getMe() => _http.getJson(
        '/users/me',
        parse: UserModel.fromJson,
      );

  Future<void> logout() async {
    await _http.clearToken();
    _session.markLoggedOut();
  }
}
