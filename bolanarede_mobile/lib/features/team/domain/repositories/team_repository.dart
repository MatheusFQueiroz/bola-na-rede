import 'package:bola_na_rede/features/team/domain/entities/team.dart';

abstract class TeamRepository {
  Future<List<Team>> getTeams();
  Future<Team> getTeamById(String id);
  Future<Team> createTeam({
    required String name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
  });
  Future<List<TeamMember>> getMembers(String teamId);
  Future<void> joinTeam(String teamId);
  Future<void> leaveTeam(String teamId);
  Future<void> removeMember(String teamId, String userId);
}
