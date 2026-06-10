import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/search/data/repositories/search_repository_provider.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

class SearchResult {
  final List<Match> matches;
  final List<Team> teams;
  final String query;

  const SearchResult({
    required this.matches,
    required this.teams,
    required this.query,
  });
}

class SearchVM extends AsyncNotifier<SearchResult> {
  @override
  Future<SearchResult> build() async => const SearchResult(
        matches: [],
        teams: [],
        query: '',
      );

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(searchRepositoryProvider);
      final results = await Future.wait([
        repo.searchMatches(query),
        repo.searchTeams(query),
      ]);
      return SearchResult(
        matches: results[0] as List<Match>,
        teams: results[1] as List<Team>,
        query: query,
      );
    });
  }

  void clear() {
    state = const AsyncData(
      SearchResult(matches: [], teams: [], query: ''),
    );
  }
}

final searchProvider =
    AsyncNotifierProvider<SearchVM, SearchResult>(SearchVM.new);
