import '../../../match/domain/entities/match.dart';
import '../../../team/domain/entities/team.dart';

abstract class HomeRepository {
  Future<Match?> getNextMatch(String teamId);
  Future<Match?> getPendingRequest(String teamId);
  Future<Team?> getMyTeam(String teamId);
}
