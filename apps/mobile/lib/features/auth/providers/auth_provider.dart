import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../data/auth_api.dart';

final currentUserProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(ref.watch(authApiProvider)),
);

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier(this._api) : super(const AsyncValue.data(null)) {
    // Defer API call so login screen opens even if server is offline
    Future.microtask(_load);
  }

  final AuthApi _api;

  Future<void> _load() async {
    try {
      final user = await _api.getMe();
      state = AsyncValue.data(user);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<UserModel> verifyOtp(String phone, String code, {String? role}) async {
    state = const AsyncValue.loading();
    final user = await _api.verifyOtp(phone, code, role: role);
    state = AsyncValue.data(user);
    return user;
  }

  Future<void> logout() async {
    await _api.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> refresh() => _load();
}
