import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/team/data/repositories/team_repository_provider.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/domain/repositories/team_repository.dart';

enum TeamStatus { idle, loading, success, error }

class TeamState {
  final TeamStatus status;
  final List<Team> teams;
  final String? error;

  const TeamState({required this.status, required this.teams, this.error});

  const TeamState.initial()
      : status = TeamStatus.idle,
        teams = const [],
        error = null;

  TeamState copyWith({
    TeamStatus? status,
    List<Team>? teams,
    String? error,
  }) =>
      TeamState(
        status: status ?? this.status,
        teams: teams ?? this.teams,
        error: error ?? this.error,
      );
}

final teamViewModelProvider =
    NotifierProvider<TeamViewModel, TeamState>(TeamViewModel.new);

class TeamViewModel extends Notifier<TeamState> {
  @override
  TeamState build() => const TeamState.initial();

  TeamRepository get _repo => ref.read(teamRepositoryProvider);

  Future<void> loadTeams() async {
    state = state.copyWith(status: TeamStatus.loading, error: null);
    try {
      final teams = await _repo.getTeams();
      state = state.copyWith(status: TeamStatus.success, teams: teams);
    } catch (_) {
      state = state.copyWith(
          status: TeamStatus.error,
          error: 'Não foi possível carregar os times.');
    }
  }
}
