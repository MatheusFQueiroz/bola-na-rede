import 'package:bola_na_rede/features/match/data/datasources/match_mock_datasource.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/domain/repositories/match_repository.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchDataSource dataSource;

  MatchRepositoryImpl({required this.dataSource});

  @override
  Future<List<Match>> getMatches() => dataSource.getMatches();

  @override
  Future<Match> getMatchById(String id) => dataSource.getMatchById(id);

  @override
  Future<void> createMatch(Match match) => dataSource.createMatch(match);
}
