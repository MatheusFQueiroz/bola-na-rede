import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/profile/data/repositories/profile_repository_provider.dart';

class ProfileData {
  final PlayerProfile profile;
  final List<Map<String, dynamic>> recentMatches;

  const ProfileData({required this.profile, required this.recentMatches});

  int get totalMatches => 42;
  int get totalGoals => 28;
  int get totalWins => 28;
  String get winRate => '67%';
}

class ProfileVM extends AsyncNotifier<ProfileData> {
  @override
  Future<ProfileData> build() async {
    final userId =
        ref.read(authViewModelProvider).value?.userId ?? 'user-001';
    final repo = ref.watch(profileRepositoryProvider);
    final results = await Future.wait([
      repo.getProfile(userId),
      repo.getRecentMatches(userId),
    ]);
    return ProfileData(
      profile: results[0] as PlayerProfile,
      recentMatches: results[1] as List<Map<String, dynamic>>,
    );
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileVM, ProfileData>(ProfileVM.new);
