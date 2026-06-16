import 'package:bola_na_rede/features/team/data/datasources/team_mock_datasource.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/domain/repositories/team_repository.dart';

class TeamRepositoryImpl implements TeamRepository {
  final TeamDataSource dataSource;

  TeamRepositoryImpl({required this.dataSource});

  @override
  Future<List<Team>> getTeams() => dataSource.getTeams();

  @override
  Future<Team> getTeamById(String id) => dataSource.getTeamById(id);
}
