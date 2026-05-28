import 'package:bola_na_rede/features/ranking/data/datasources/ranking_mock_datasource.dart';
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';
import 'package:bola_na_rede/features/ranking/domain/repositories/ranking_repository.dart';

class RankingRepositoryImpl implements RankingRepository {
  final RankingDataSource dataSource;

  RankingRepositoryImpl({required this.dataSource});

  @override
  Future<List<TeamRanking>> getTeamRankings() => dataSource.getTeamRankings();

  @override
  Future<List<PlayerRanking>> getPlayerRankings() =>
      dataSource.getPlayerRankings();
}
