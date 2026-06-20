import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bola_na_rede/features/auth/domain/entities/user.dart';

class ProfileCache {
  static String _key(String userId) => 'cached_profile_$userId';

  Future<PlayerProfile?> read(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) return null;
    try {
      return PlayerProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Exception catch (_) {
      return null;
    }
  }

  Future<void> save(String userId, PlayerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(profile.toJson()));
  }

  Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}

final profileCacheProvider = Provider<ProfileCache>((_) => ProfileCache());
