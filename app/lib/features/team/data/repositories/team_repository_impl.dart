import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_mock_datasource.dart';

class TeamRepositoryImpl implements TeamRepository {
  final TeamDataSource dataSource;

  TeamRepositoryImpl({required this.dataSource});

  @override
  Future<List<Team>> getTeams() => dataSource.getTeams();

  @override
  Future<Team> getTeamById(String id) => dataSource.getTeamById(id);
}
