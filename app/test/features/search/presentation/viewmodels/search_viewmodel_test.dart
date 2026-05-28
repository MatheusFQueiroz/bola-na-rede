import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/search/data/repositories/search_repository_provider.dart';
import 'package:bola_na_rede/features/search/domain/repositories/search_repository.dart';
import 'package:bola_na_rede/features/search/presentation/viewmodels/search_viewmodel.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

class FakeSearchRepository implements SearchRepository {
  @override
  Future<List<Match>> searchMatches(String query) async => [];
  @override
  Future<List<Team>> searchTeams(String query) async => [];
}

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          searchRepositoryProvider.overrideWithValue(FakeSearchRepository()),
        ],
      );

  group('SearchViewModel', () {
    test('initial state is idle with empty lists', () {
      final c = makeContainer();
      addTearDown(c.dispose);

      final s = c.read(searchViewModelProvider);

      expect(s.status, SearchStatus.idle);
      expect(s.matches, isEmpty);
    });

    test('search sets status to success', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(searchViewModelProvider.notifier).search('fusão');

      expect(c.read(searchViewModelProvider).status, SearchStatus.success);
    });

    test('clear resets to idle', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(searchViewModelProvider.notifier).search('fusão');
      c.read(searchViewModelProvider.notifier).clear();

      expect(c.read(searchViewModelProvider).status, SearchStatus.idle);
    });
  });
}
