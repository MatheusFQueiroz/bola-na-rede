import 'package:flutter/material.dart';

import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/home/domain/repositories/home_repository.dart';

enum HomeViewState { idle, loading, success, error }

class HomeViewModel extends ChangeNotifier {
  final HomeRepository repository;

  HomeViewModel({required this.repository});

  HomeViewState _state = HomeViewState.idle;
  Match? _nextMatch;
  Match? _pendingRequest;
  Team? _myTeam;
  String? _error;

  HomeViewState get state => _state;
  Match? get nextMatch => _nextMatch;
  Match? get pendingRequest => _pendingRequest;
  Team? get myTeam => _myTeam;
  String? get error => _error;

  int get myRank => 3;
  int get playerCount => 6;
  int get winStreak => 8;

  Future<void> loadHome() async {
    _state = HomeViewState.loading;
    _error = null;
    notifyListeners();

    try {
      const teamId = 'team-001';

      final results = await Future.wait([
        repository.getNextMatch(teamId),
        repository.getPendingRequest(teamId),
        repository.getMyTeam(teamId),
      ]);

      _nextMatch = results[0] as Match?;
      _pendingRequest = results[1] as Match?;
      _myTeam = results[2] as Team?;

      _state = HomeViewState.success;
    } catch (e) {
      _error = 'Não foi possível carregar a home.';
      _state = HomeViewState.error;
    }
    notifyListeners();
  }
}
