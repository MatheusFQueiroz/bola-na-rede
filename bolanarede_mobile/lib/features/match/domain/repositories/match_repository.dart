import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_request.dart';

abstract class MatchRepository {
  Future<List<Match>> getMatches();
  Future<Match> getMatchById(String id);
  Future<void> createMatch(Match match);
  Future<List<MatchRequest>> getMatchRequests({String? city});
  Future<MatchRequest> createMatchRequest(String sport);
  Future<void> cancelMatchRequest(String requestId);
  Future<void> acceptMatch(String matchId);
  Future<Match> getGame(String gameId);
  Future<void> submitResult(
    String gameId, {
    required int playerAGoals,
    required int playerBGoals,
    required int playerAAssists,
    required int playerBAssists,
  });
  Future<void> confirmResult(String gameId);
  Future<void> disputeResult(String gameId);
}
