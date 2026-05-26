import 'package:flutter/material.dart';
import '../../../match/domain/entities/match.dart';
import '../../../team/domain/entities/team.dart';
import '../../domain/repositories/search_repository.dart';

enum SearchViewState { idle, loading, success, error }

class SearchViewModel extends ChangeNotifier {
  final SearchRepository repository;

  SearchViewModel({required this.repository});

  SearchViewState _state = SearchViewState.idle;
  List<Match> _matches = [];
  List<Team> _teams = [];
  String _query = '';
  String? _error;

  SearchViewState get state => _state;
  List<Match> get matches => _matches;
  List<Team> get teams => _teams;
  String get query => _query;
  String? get error => _error;

  Future<void> search(String query) async {
    _query = query;
    _state = SearchViewState.loading;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.searchMatches(query),
        repository.searchTeams(query),
      ]);
      _matches = results[0] as List<Match>;
      _teams = results[1] as List<Team>;
      _state = SearchViewState.success;
    } catch (e) {
      _error = 'Não foi possível realizar a busca.';
      _state = SearchViewState.error;
    }
    notifyListeners();
  }

  void clear() {
    _query = '';
    _matches = [];
    _teams = [];
    _state = SearchViewState.idle;
    notifyListeners();
  }
}
