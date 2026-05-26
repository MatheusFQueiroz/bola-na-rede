import '../../../match/domain/entities/match.dart';
import '../../../team/domain/entities/team.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_mock_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchDataSource dataSource;

  SearchRepositoryImpl({required this.dataSource});

  @override
  Future<List<Match>> searchMatches(String query) =>
      dataSource.searchMatches(query);

  @override
  Future<List<Team>> searchTeams(String query) => dataSource.searchTeams(query);
}
