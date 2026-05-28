import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/ranking/data/repositories/ranking_repository_provider.dart';
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';
import 'package:bola_na_rede/features/ranking/domain/repositories/ranking_repository.dart';
import 'package:bola_na_rede/features/ranking/presentation/viewmodels/ranking_viewmodel.dart';

class FakeRankingRepository implements RankingRepository {
  @override
  Future<List<TeamRanking>> getTeamRankings() async => const [
        TeamRanking(
          id: 't-1',
          name: 'Fusão',
          city: 'Curitiba',
          points: 30,
          wins: 10,
          draws: 0,
          losses: 0,
          goalsFor: 30,
          goalsAgainst: 0,
          matchesPlayed: 10,
          rank: 1,
        ),
      ];

  @override
  Future<List<PlayerRanking>> getPlayerRankings() async => [];
}

void main() {
  group('RankingViewModel', () {
    ProviderContainer makeContainer() => ProviderContainer(
          overrides: [
            rankingRepositoryProvider.overrideWithValue(FakeRankingRepository()),
          ],
        );

    test('initial state is idle with empty lists', () {
      final c = makeContainer();
      addTearDown(c.dispose);

      final state = c.read(rankingViewModelProvider);

      expect(state.status, RankingStatus.idle);
      expect(state.teamRankings, isEmpty);
    });

    test('loadRankings populates teamRankings', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(rankingViewModelProvider.notifier).loadRankings();

      expect(c.read(rankingViewModelProvider).status, RankingStatus.success);
      expect(c.read(rankingViewModelProvider).teamRankings, hasLength(1));
    });
  });
}
