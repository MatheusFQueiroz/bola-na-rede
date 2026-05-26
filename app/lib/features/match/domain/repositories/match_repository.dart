import '../entities/match.dart';
import '../entities/match_request.dart';
import '../entities/match_result.dart';

abstract class MatchRepository {
  Future<List<Match>> getMatches();
  Future<Match> getMatchById(String id);
  Future<void> createMatch(Match match);
}
