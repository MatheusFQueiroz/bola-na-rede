import 'package:bola_na_rede/features/team/domain/entities/team.dart';

abstract class TeamRepository {
  Future<List<Team>> getTeams();
  Future<Team> getTeamById(String id);
}
