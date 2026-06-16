import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/ranking/data/repositories/ranking_repository_provider.dart';
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';

class RankingData {
  final List<TeamRanking> teamRankings;
  final List<PlayerRanking> playerRankings;

  const RankingData({
    required this.teamRankings,
    required this.playerRankings,
  });
}

class RankingVM extends AsyncNotifier<RankingData> {
  @override
  Future<RankingData> build() async {
    final repo = ref.watch(rankingRepositoryProvider);
    final results = await Future.wait([
      repo.getTeamRankings(),
      repo.getPlayerRankings(),
    ]);
    return RankingData(
      teamRankings: results[0] as List<TeamRanking>,
      playerRankings: results[1] as List<PlayerRanking>,
    );
  }
}

final rankingProvider =
    AsyncNotifierProvider<RankingVM, RankingData>(RankingVM.new);
