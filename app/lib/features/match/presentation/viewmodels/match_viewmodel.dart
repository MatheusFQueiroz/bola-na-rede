import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/shared/snapshots.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/match/data/repositories/match_repository_provider.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/domain/repositories/match_repository.dart';

enum MatchLoadStatus { idle, loading, success, error }

class MatchState {
  final MatchLoadStatus listStatus;
  final List<Match> matches;
  final String? listError;
  final Match? selectedMatch;
  final MatchLoadStatus createStatus;
  final String? createError;

  const MatchState({
    required this.listStatus,
    required this.matches,
    this.listError,
    this.selectedMatch,
    required this.createStatus,
    this.createError,
  });

  const MatchState.initial()
      : listStatus = MatchLoadStatus.idle,
        matches = const [],
        listError = null,
        selectedMatch = null,
        createStatus = MatchLoadStatus.idle,
        createError = null;

  List<Match> get scheduledMatches =>
      matches.where((m) => m.status == MatchStatus.scheduled).toList();
  List<Match> get completedMatches =>
      matches.where((m) => m.status == MatchStatus.completed).toList();

  MatchState copyWith({
    MatchLoadStatus? listStatus,
    List<Match>? matches,
    String? listError,
    Match? selectedMatch,
    MatchLoadStatus? createStatus,
    String? createError,
  }) =>
      MatchState(
        listStatus: listStatus ?? this.listStatus,
        matches: matches ?? this.matches,
        listError: listError ?? this.listError,
        selectedMatch: selectedMatch ?? this.selectedMatch,
        createStatus: createStatus ?? this.createStatus,
        createError: createError ?? this.createError,
      );
}

final matchViewModelProvider =
    NotifierProvider<MatchViewModel, MatchState>(MatchViewModel.new);

class MatchViewModel extends Notifier<MatchState> {
  @override
  MatchState build() => const MatchState.initial();

  MatchRepository get _repo => ref.read(matchRepositoryProvider);

  Future<void> loadMatches() async {
    state = state.copyWith(listStatus: MatchLoadStatus.loading, listError: null);
    try {
      final matches = await _repo.getMatches();
      state = state.copyWith(
          listStatus: MatchLoadStatus.success, matches: matches);
    } catch (_) {
      state = state.copyWith(
          listStatus: MatchLoadStatus.error,
          listError: 'Não foi possível carregar as partidas.');
    }
  }

  Future<void> loadMatchDetail(String matchId) async {
    try {
      final match = await _repo.getMatchById(matchId);
      state = state.copyWith(selectedMatch: match);
    } catch (_) {
      state = state.copyWith(selectedMatch: null);
    }
  }

  Future<bool> createMatch({
    required String teamBId,
    required String teamBName,
    required String teamBCity,
    required DateTime scheduledDate,
    required String timeStart,
    required String timeEnd,
    String? fieldId,
    String? fieldName,
    String? fieldAddress,
  }) async {
    state = state.copyWith(
        createStatus: MatchLoadStatus.loading, createError: null);
    try {
      final authState = ref.read(authViewModelProvider);
      final teamAId = authState.currentTeamId;
      final teamAName = authState.currentUser?.displayName ?? 'Meu Time';

      final newMatch = Match(
        id: const Uuid().v4(),
        proposalId: const Uuid().v4(),
        teamAId: teamAId,
        teamBId: teamBId,
        teamASnapshot: TeamSnapshot(
          teamId: teamAId,
          name: teamAName,
          city: authState.currentUser?.city ?? 'Curitiba',
        ),
        teamBSnapshot:
            TeamSnapshot(teamId: teamBId, name: teamBName, city: teamBCity),
        fieldId: fieldId,
        fieldSnapshot: fieldId != null
            ? FieldSnapshot(
                fieldId: fieldId,
                name: fieldName ?? 'Campo',
                address: fieldAddress,
              )
            : null,
        scheduledDate: scheduledDate,
        scheduledTimeStart: timeStart,
        scheduledTimeEnd: timeEnd,
        status: MatchStatus.scheduled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repo.createMatch(newMatch);
      await loadMatches();
      state = state.copyWith(createStatus: MatchLoadStatus.success);
      return true;
    } catch (_) {
      state = state.copyWith(
          createStatus: MatchLoadStatus.error,
          createError: 'Não foi possível criar a partida.');
      return false;
    }
  }
}
