import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}

class SharedPreferencesTokenStorage implements TokenStorage {
  static const _key = 'auth_token';

  @override
  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SharedPreferencesTokenStorage(),
);
