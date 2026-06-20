import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/profile/data/datasources/profile_cache.dart';
import 'package:bola_na_rede/features/profile/data/repositories/profile_repository_provider.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/profile_repository.dart';

class ProfileData {
  final PlayerProfile profile;
  final List<Map<String, dynamic>> recentMatches;

  const ProfileData({required this.profile, required this.recentMatches});

  int get totalMatches => recentMatches.length;
  int get totalGoals => 0;
  int get totalWins =>
      recentMatches.where((m) => m['result'] == 'win').length;
  String get winRate => totalMatches == 0
      ? '0%'
      : '${(totalWins / totalMatches * 100).round()}%';
}

class ProfileVM extends AsyncNotifier<ProfileData> {
  @override
  Future<ProfileData> build() async {
    final userId =
        ref.read(authViewModelProvider).value?.userId ?? 'user-001';
    final repo = ref.watch(profileRepositoryProvider);
    final cache = ref.read(profileCacheProvider);

    final cached = await cache.read(userId);

    if (cached != null) {
      // Show cached profile instantly, refresh in background
      unawaited(_refreshFromApi(userId, repo, cache));
      return ProfileData(profile: cached, recentMatches: const []);
    }

    return _fetchAndCache(userId, repo, cache);
  }

  Future<ProfileData> _fetchAndCache(
    String userId,
    ProfileRepository repo,
    ProfileCache cache,
  ) async {
    final results = await Future.wait([
      repo.getProfile(userId),
      repo.getRecentMatches(userId),
    ]);
    final profile = results[0] as PlayerProfile;
    await cache.save(userId, profile);
    return ProfileData(
      profile: profile,
      recentMatches: results[1] as List<Map<String, dynamic>>,
    );
  }

  Future<void> _refreshFromApi(
    String userId,
    ProfileRepository repo,
    ProfileCache cache,
  ) async {
    try {
      final fresh = await _fetchAndCache(userId, repo, cache);
      state = AsyncData(fresh);
    } on Exception catch (_) {
      // Keep cached data on network error
    }
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileVM, ProfileData>(ProfileVM.new);
