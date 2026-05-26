import '../entities/team.dart';

abstract class TeamRepository {
  Future<List<Team>> getTeams();
  Future<Team> getTeamById(String id);
}
