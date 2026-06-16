import 'package:bola_na_rede/features/home/data/datasources/home_mock_datasource.dart';
import 'package:bola_na_rede/features/home/domain/repositories/home_repository.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDataSource dataSource;

  HomeRepositoryImpl({required this.dataSource});

  @override
  Future<Match?> getNextMatch(String teamId) => dataSource.getNextMatch(teamId);

  @override
  Future<Match?> getPendingRequest(String teamId) =>
      dataSource.getPendingRequest(teamId);

  @override
  Future<Team?> getMyTeam(String teamId) => dataSource.getMyTeam(teamId);
}
