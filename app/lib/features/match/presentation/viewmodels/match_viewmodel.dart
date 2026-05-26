import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/shared/snapshots.dart';

enum MatchViewState { idle, loading, success, error }

class MatchViewModel extends ChangeNotifier {
  final MatchRepository repository;
  final AuthViewModel authViewModel;

  MatchViewModel({
    required this.repository,
    required this.authViewModel,
  });

  // — Lista
  MatchViewState _listState = MatchViewState.idle;
  List<Match> _matches = [];
  String? _listError;

  MatchViewState get listState => _listState;
  List<Match> get matches => _matches;
  String? get listError => _listError;

  // — Detalhe
  Match? _selectedMatch;
  Match? get selectedMatch => _selectedMatch;

  // — Criação
  MatchViewState _createState = MatchViewState.idle;
  MatchViewState get createState => _createState;
  String? _createError;
  String? get createError => _createError;

  Future<void> loadMatches() async {
    _listState = MatchViewState.loading;
    _listError = null;
    notifyListeners();

    try {
      _matches = await repository.getMatches();
      _listState = MatchViewState.success;
    } catch (e) {
      _listError = 'Não foi possível carregar as partidas.';
      _listState = MatchViewState.error;
    }
    notifyListeners();
  }

  Future<void> loadMatchDetail(String matchId) async {
    try {
      _selectedMatch = await repository.getMatchById(matchId);
      notifyListeners();
    } catch (e) {
      _selectedMatch = null;
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
    _createState = MatchViewState.loading;
    _createError = null;
    notifyListeners();

    try {
      // pega dados do usuário logado
      final currentUser = authViewModel.currentUser;
      final teamAId = authViewModel.currentTeamId;
      final teamAName = currentUser?.displayName ?? 'Meu Time';

      // monta snapshots conforme db-game-service.md
      final teamASnapshot = TeamSnapshot(
        teamId: teamAId,
        name: teamAName,
        city: currentUser?.city ?? 'Curitiba',
      );

      final teamBSnapshot = TeamSnapshot(
        teamId: teamBId,
        name: teamBName,
        city: teamBCity,
      );

      // snapshot do campo se informado
      final fieldSnapshot = fieldId != null
          ? FieldSnapshot(
              fieldId: fieldId,
              name: fieldName ?? 'Campo',
              address: fieldAddress,
            )
          : null;

      final newMatch = Match(
        id: const Uuid().v4(),
        proposalId: const Uuid().v4(),
        teamAId: teamAId,
        teamBId: teamBId,
        teamASnapshot: teamASnapshot,
        teamBSnapshot: teamBSnapshot,
        fieldId: fieldId,
        fieldSnapshot: fieldSnapshot,
        scheduledDate: scheduledDate,
        scheduledTimeStart: timeStart,
        scheduledTimeEnd: timeEnd,
        status: MatchStatus.scheduled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createMatch(newMatch);
      await loadMatches();
      _createState = MatchViewState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _createError = 'Não foi possível criar a partida.';
      _createState = MatchViewState.error;
      notifyListeners();
      return false;
    }
  }

  List<Match> get scheduledMatches =>
      _matches.where((m) => m.status == MatchStatus.scheduled).toList();

  List<Match> get completedMatches =>
      _matches.where((m) => m.status == MatchStatus.completed).toList();
}
