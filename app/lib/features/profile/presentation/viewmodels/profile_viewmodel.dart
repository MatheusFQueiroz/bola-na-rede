import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/profile/data/repositories/profile_repository_provider.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/profile_repository.dart';

enum ProfileStatus { idle, loading, success, error }

class ProfileState {
  final ProfileStatus status;
  final PlayerProfile? profile;
  final List<Map<String, dynamic>> recentMatches;
  final String? error;

  const ProfileState({
    required this.status,
    this.profile,
    required this.recentMatches,
    this.error,
  });

  const ProfileState.initial()
      : status = ProfileStatus.idle,
        profile = null,
        recentMatches = const [],
        error = null;

  ProfileState copyWith({
    ProfileStatus? status,
    PlayerProfile? profile,
    List<Map<String, dynamic>>? recentMatches,
    String? error,
  }) =>
      ProfileState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        recentMatches: recentMatches ?? this.recentMatches,
        error: error ?? this.error,
      );

  int get totalMatches => 42;
  int get totalGoals => 28;
  int get totalWins => 28;
  String get winRate => '67%';
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState.initial();

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  Future<void> loadProfile() async {
    state = state.copyWith(status: ProfileStatus.loading, error: null);
    try {
      const userId = 'user-001';
      final results = await Future.wait([
        _repo.getProfile(userId),
        _repo.getRecentMatches(userId),
      ]);
      state = state.copyWith(
        status: ProfileStatus.success,
        profile: results[0] as PlayerProfile,
        recentMatches: results[1] as List<Map<String, dynamic>>,
      );
    } catch (_) {
      state = state.copyWith(
        status: ProfileStatus.error,
        error: 'Não foi possível carregar o perfil.',
      );
    }
  }
}
