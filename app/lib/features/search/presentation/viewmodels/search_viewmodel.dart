import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/search/data/repositories/search_repository_provider.dart';
import 'package:bola_na_rede/features/search/domain/repositories/search_repository.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

enum SearchStatus { idle, loading, success, error }

class SearchState {
  final SearchStatus status;
  final List<Match> matches;
  final List<Team> teams;
  final String query;
  final String? error;

  const SearchState({
    required this.status,
    required this.matches,
    required this.teams,
    required this.query,
    this.error,
  });

  const SearchState.initial()
      : status = SearchStatus.idle,
        matches = const [],
        teams = const [],
        query = '',
        error = null;

  SearchState copyWith({
    SearchStatus? status,
    List<Match>? matches,
    List<Team>? teams,
    String? query,
    String? error,
  }) =>
      SearchState(
        status: status ?? this.status,
        matches: matches ?? this.matches,
        teams: teams ?? this.teams,
        query: query ?? this.query,
        error: error ?? this.error,
      );
}

final searchViewModelProvider =
    NotifierProvider<SearchViewModel, SearchState>(SearchViewModel.new);

class SearchViewModel extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState.initial();

  SearchRepository get _repo => ref.read(searchRepositoryProvider);

  Future<void> search(String query) async {
    state = state.copyWith(
        status: SearchStatus.loading, query: query, error: null);
    try {
      final results = await Future.wait([
        _repo.searchMatches(query),
        _repo.searchTeams(query),
      ]);
      state = state.copyWith(
        status: SearchStatus.success,
        matches: results[0] as List<Match>,
        teams: results[1] as List<Team>,
      );
    } catch (_) {
      state = state.copyWith(
          status: SearchStatus.error,
          error: 'Não foi possível realizar a busca.');
    }
  }

  void clear() {
    state = const SearchState.initial();
  }
}
