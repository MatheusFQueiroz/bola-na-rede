import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';

abstract class RankingRepository {
  Future<List<TeamRanking>> getTeamRankings();
  Future<List<PlayerRanking>> getPlayerRankings();
}
