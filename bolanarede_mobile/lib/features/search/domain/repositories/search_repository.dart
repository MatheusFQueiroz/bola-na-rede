import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

abstract class SearchRepository {
  Future<List<Match>> searchMatches(String query);
  Future<List<Team>> searchTeams(String query);
}
