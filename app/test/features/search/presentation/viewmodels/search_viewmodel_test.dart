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

ProviderContainer makeContainer() => ProviderContainer(
      overrides: [
        searchRepositoryProvider.overrideWithValue(FakeSearchRepository()),
      ],
    );

void main() {
  group('searchProvider', () {
    test('initial state resolves to empty result', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      final result = await c.read(searchProvider.future);
      expect(result.matches, isEmpty);
      expect(result.teams, isEmpty);
    });

    test('search resolves with results', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(searchProvider.future);
      await c.read(searchProvider.notifier).search('fusão');

      final result = c.read(searchProvider).value;
      expect(result, isNotNull);
      expect(result!.matches, isEmpty);
    });

    test('clear resets to empty result', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(searchProvider.notifier).search('fusão');
      c.read(searchProvider.notifier).clear();

      final result = c.read(searchProvider).value;
      expect(result?.query, '');
    });
  });
}
