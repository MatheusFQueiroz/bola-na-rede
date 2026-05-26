import 'package:flutter/material.dart';
import '../../domain/entities/ranking.dart';
import '../../domain/repositories/ranking_repository.dart';

enum RankingViewState { idle, loading, success, error }

class RankingViewModel extends ChangeNotifier {
  final RankingRepository repository;

  RankingViewModel({required this.repository});

  RankingViewState _state = RankingViewState.idle;
  List<TeamRanking> _teamRankings = [];
  List<PlayerRanking> _playerRankings = [];
  String? _error;

  RankingViewState get state => _state;
  List<TeamRanking> get teamRankings => _teamRankings;
  List<PlayerRanking> get playerRankings => _playerRankings;
  String? get error => _error;

  Future<void> loadRankings() async {
    _state = RankingViewState.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.getTeamRankings(),
        repository.getPlayerRankings(),
      ]);
      _teamRankings = results[0] as List<TeamRanking>;
      _playerRankings = results[1] as List<PlayerRanking>;
      _state = RankingViewState.success;
    } catch (e) {
      _error = 'Não foi possível carregar o ranking.';
      _state = RankingViewState.error;
    }
    notifyListeners();
  }
}
