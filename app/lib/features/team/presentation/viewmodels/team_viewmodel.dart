import 'package:flutter/material.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';

enum TeamViewState { idle, loading, success, error }

class TeamViewModel extends ChangeNotifier {
  final TeamRepository repository;

  TeamViewModel({required this.repository});

  TeamViewState _state = TeamViewState.idle;
  List<Team> _teams = [];
  String? _error;

  TeamViewState get state => _state;
  List<Team> get teams => _teams;
  String? get error => _error;

  Future<void> loadTeams() async {
    _state = TeamViewState.loading;
    _error = null;
    notifyListeners();

    try {
      _teams = await repository.getTeams();
      _state = TeamViewState.success;
    } catch (e) {
      _error = 'Não foi possível carregar os times.';
      _state = TeamViewState.error;
    }
    notifyListeners();
  }
}
