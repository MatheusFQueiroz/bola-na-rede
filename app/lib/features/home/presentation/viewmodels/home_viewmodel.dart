import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/home/data/repositories/home_repository_provider.dart';
import 'package:bola_na_rede/features/home/domain/repositories/home_repository.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/ranking/presentation/viewmodels/ranking_viewmodel.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

enum HomeStatus { idle, loading, success, error }

class HomeState {
  final HomeStatus status;
  final Match? nextMatch;
  final Match? pendingRequest;
  final Team? myTeam;
  final String? error;

  const HomeState({
    required this.status,
    this.nextMatch,
    this.pendingRequest,
    this.myTeam,
    this.error,
  });

  const HomeState.initial()
      : status = HomeStatus.idle,
        nextMatch = null,
        pendingRequest = null,
        myTeam = null,
        error = null;

  int get myRank => 3;
  int get playerCount => 6;
  int get winStreak => 8;

  HomeState copyWith({
    HomeStatus? status,
    Match? nextMatch,
    Match? pendingRequest,
    Team? myTeam,
    String? error,
  }) =>
      HomeState(
        status: status ?? this.status,
        nextMatch: nextMatch ?? this.nextMatch,
        pendingRequest: pendingRequest ?? this.pendingRequest,
        myTeam: myTeam ?? this.myTeam,
        error: error ?? this.error,
      );
}

final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState.initial();

  HomeRepository get _repo => ref.read(homeRepositoryProvider);

  Future<void> loadHome() async {
    state = state.copyWith(status: HomeStatus.loading, error: null);
    try {
      final teamId = ref.read(authViewModelProvider).currentTeamId;
      final results = await Future.wait([
        _repo.getNextMatch(teamId),
        _repo.getPendingRequest(teamId),
        _repo.getMyTeam(teamId),
      ]);

      final rankingState = ref.read(rankingViewModelProvider);
      if (rankingState.status == RankingStatus.idle) {
        await ref.read(rankingViewModelProvider.notifier).loadRankings();
      }

      state = HomeState(
        status: HomeStatus.success,
        nextMatch: results[0] as Match?,
        pendingRequest: results[1] as Match?,
        myTeam: results[2] as Team?,
      );
    } catch (_) {
      state = state.copyWith(
        status: HomeStatus.error,
        error: 'Não foi possível carregar a home.',
      );
    }
  }
}
