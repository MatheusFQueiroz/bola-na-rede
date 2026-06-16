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

ProviderContainer makeContainer() => ProviderContainer(
      overrides: [
        rankingRepositoryProvider.overrideWithValue(FakeRankingRepository()),
      ],
    );

void main() {
  group('rankingProvider', () {
    test('starts loading', () {
      final c = makeContainer();
      addTearDown(c.dispose);

      expect(c.read(rankingProvider), isA<AsyncLoading<RankingData>>());
    });

    test('resolves and populates teamRankings', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      final data = await c.read(rankingProvider.future);
      expect(data.teamRankings, hasLength(1));
      expect(data.playerRankings, isEmpty);
    });
  });
}
