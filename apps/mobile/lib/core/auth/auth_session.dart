import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_storage.dart';

/// Drives GoRouter redirects without async redirect (avoids startup crashes).
final authSessionProvider = Provider<AuthSession>((ref) {
  final session = AuthSession(ref.read(tokenStorageProvider));
  ref.onDispose(session.dispose);
  return session;
});

class AuthSession extends ChangeNotifier {
  AuthSession(this._storage);

  final TokenStorage _storage;

  bool ready = false;
  bool loggedIn = false;

  Future<void> bootstrap() async {
    try {
      final token = await _storage.readAccessToken();
      loggedIn = token != null && token.isNotEmpty;
    } catch (_) {
      loggedIn = false;
    }
    ready = true;
    notifyListeners();
  }

  void markLoggedIn() {
    loggedIn = true;
    notifyListeners();
  }

  void markLoggedOut() {
    loggedIn = false;
    notifyListeners();
  }
}
