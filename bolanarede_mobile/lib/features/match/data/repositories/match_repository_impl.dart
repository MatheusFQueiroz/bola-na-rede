import 'package:bola_na_rede/features/match/data/datasources/match_mock_datasource.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_request.dart';
import 'package:bola_na_rede/features/match/domain/repositories/match_repository.dart';

class MatchRepositoryImpl implements MatchRepository {
  MatchRepositoryImpl({required this.dataSource});

  final MatchDataSource dataSource;

  @override
  Future<List<Match>> getMatches() => dataSource.getMatches();

  @override
  Future<Match> getMatchById(String id) => dataSource.getMatchById(id);

  @override
  Future<void> createMatch(Match match) => dataSource.createMatch(match);

  @override
  Future<List<MatchRequest>> getMatchRequests({String? city}) =>
      dataSource.getMatchRequests(city: city);

  @override
  Future<MatchRequest> createMatchRequest(String sport) =>
      dataSource.createMatchRequest(sport);

  @override
  Future<void> cancelMatchRequest(String requestId) =>
      dataSource.cancelMatchRequest(requestId);

  @override
  Future<void> acceptMatch(String matchId) => dataSource.acceptMatch(matchId);

  @override
  Future<Match> getGame(String gameId) => dataSource.getGame(gameId);

  @override
  Future<void> submitResult(
    String gameId, {
    required int playerAGoals,
    required int playerBGoals,
    required int playerAAssists,
    required int playerBAssists,
  }) =>
      dataSource.submitResult(
        gameId,
        playerAGoals: playerAGoals,
        playerBGoals: playerBGoals,
        playerAAssists: playerAAssists,
        playerBAssists: playerBAssists,
      );

  @override
  Future<void> confirmResult(String gameId) => dataSource.confirmResult(gameId);

  @override
  Future<void> disputeResult(String gameId) => dataSource.disputeResult(gameId);
}
