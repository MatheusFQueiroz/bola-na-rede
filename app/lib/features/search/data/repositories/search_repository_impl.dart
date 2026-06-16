import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/search/data/datasources/search_mock_datasource.dart';
import 'package:bola_na_rede/features/search/domain/repositories/search_repository.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchDataSource dataSource;

  SearchRepositoryImpl({required this.dataSource});

  @override
  Future<List<Match>> searchMatches(String query) =>
      dataSource.searchMatches(query);

  @override
  Future<List<Team>> searchTeams(String query) => dataSource.searchTeams(query);
}
