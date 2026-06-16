import 'package:bola_na_rede/features/team/data/datasources/team_mock_datasource.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/domain/repositories/team_repository.dart';

class TeamRepositoryImpl implements TeamRepository {
  TeamRepositoryImpl({required this.dataSource});

  final TeamDataSource dataSource;

  @override
  Future<List<Team>> getTeams() => dataSource.getTeams();

  @override
  Future<Team> getTeamById(String id) => dataSource.getTeamById(id);

  @override
  Future<Team> createTeam({
    required String name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
  }) =>
      dataSource.createTeam(
        name: name,
        description: description,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
      );

  @override
  Future<List<TeamMember>> getMembers(String teamId) =>
      dataSource.getMembers(teamId);

  @override
  Future<void> joinTeam(String teamId) => dataSource.joinTeam(teamId);

  @override
  Future<void> leaveTeam(String teamId) => dataSource.leaveTeam(teamId);

  @override
  Future<void> removeMember(String teamId, String userId) =>
      dataSource.removeMember(teamId, userId);
}
