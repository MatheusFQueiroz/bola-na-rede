import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';
import '../datasources/match_mock_datasource.dart';

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
