import '../../../match/domain/entities/match.dart';
import '../../../team/domain/entities/team.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_mock_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDataSource dataSource;

  HomeRepositoryImpl({required this.dataSource});

  @override
  Future<Match?> getNextMatch(String teamId) => dataSource.getNextMatch(teamId);

  @override
  Future<Match?> getPendingRequest(String teamId) =>
      dataSource.getPendingRequest(teamId);

  @override
  Future<Team?> getMyTeam(String teamId) => dataSource.getMyTeam(teamId);
}
