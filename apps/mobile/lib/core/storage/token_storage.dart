import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage.instance);

/// Persists auth token with [SharedPreferences] — stable on all Android versions
/// (flutter_secure_storage can crash on launch when Keystore/encrypted prefs fail).
class TokenStorage {
  TokenStorage._();

  static final TokenStorage instance = TokenStorage._();

  static const _accessTokenKey = 'delala_access_token';
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
  }

  Future<String?> readAccessToken() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      return prefs.getString(_accessTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAccessToken(String token) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      await prefs.setString(_accessTokenKey, token);
    } catch (_) {
      // Ignore — user can sign in again
    }
  }

  Future<void> clear() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      await prefs.remove(_accessTokenKey);
    } catch (_) {
      // Ignore
    }
  }
}
