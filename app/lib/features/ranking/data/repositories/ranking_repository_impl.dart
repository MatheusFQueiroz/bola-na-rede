import '../../domain/entities/ranking.dart';
import '../../domain/repositories/ranking_repository.dart';
import '../datasources/ranking_mock_datasource.dart';

class RankingRepositoryImpl implements RankingRepository {
  final RankingDataSource dataSource;

  RankingRepositoryImpl({required this.dataSource});

  @override
  Future<List<TeamRanking>> getTeamRankings() => dataSource.getTeamRankings();

  @override
  Future<List<PlayerRanking>> getPlayerRankings() =>
      dataSource.getPlayerRankings();
}
