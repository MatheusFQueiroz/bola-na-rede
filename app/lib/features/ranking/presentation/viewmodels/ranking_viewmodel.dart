import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/ranking/data/repositories/ranking_repository_provider.dart';
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';
import 'package:bola_na_rede/features/ranking/domain/repositories/ranking_repository.dart';

enum RankingStatus { idle, loading, success, error }

class RankingState {
  final RankingStatus status;
  final List<TeamRanking> teamRankings;
  final List<PlayerRanking> playerRankings;
  final String? error;

  const RankingState({
    required this.status,
    required this.teamRankings,
    required this.playerRankings,
    this.error,
  });

  const RankingState.initial()
      : status = RankingStatus.idle,
        teamRankings = const [],
        playerRankings = const [],
        error = null;

  RankingState copyWith({
    RankingStatus? status,
    List<TeamRanking>? teamRankings,
    List<PlayerRanking>? playerRankings,
    String? error,
  }) =>
      RankingState(
        status: status ?? this.status,
        teamRankings: teamRankings ?? this.teamRankings,
        playerRankings: playerRankings ?? this.playerRankings,
        error: error ?? this.error,
      );
}

final rankingViewModelProvider =
    NotifierProvider<RankingViewModel, RankingState>(RankingViewModel.new);

class RankingViewModel extends Notifier<RankingState> {
  @override
  RankingState build() => const RankingState.initial();

  RankingRepository get _repo => ref.read(rankingRepositoryProvider);

  Future<void> loadRankings() async {
    state = state.copyWith(status: RankingStatus.loading, error: null);
    try {
      final results = await Future.wait([
        _repo.getTeamRankings(),
        _repo.getPlayerRankings(),
      ]);
      state = state.copyWith(
        status: RankingStatus.success,
        teamRankings: results[0] as List<TeamRanking>,
        playerRankings: results[1] as List<PlayerRanking>,
      );
    } catch (_) {
      state = state.copyWith(
        status: RankingStatus.error,
        error: 'Não foi possível carregar o ranking.',
      );
    }
  }
}
