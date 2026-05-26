import '../entities/ranking.dart';

abstract class RankingRepository {
  Future<List<TeamRanking>> getTeamRankings();
  Future<List<PlayerRanking>> getPlayerRankings();
}
