import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

abstract class HomeRepository {
  Future<Match?> getNextMatch(String teamId);
  Future<Match?> getPendingRequest(String teamId);
  Future<Team?> getMyTeam(String teamId);
}
