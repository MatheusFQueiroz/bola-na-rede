import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_request.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_result.dart';

abstract class MatchRepository {
  Future<List<Match>> getMatches();
  Future<Match> getMatchById(String id);
  Future<void> createMatch(Match match);
}
