import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:bola_na_rede/features/match/data/repositories/match_repository_provider.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_request.dart';
import 'package:bola_na_rede/features/match/domain/repositories/match_repository.dart';
import 'package:bola_na_rede/features/match/presentation/viewmodels/match_viewmodel.dart';
import '../../../../helpers/fake_repositories.dart';

class FakeMatchRepository implements MatchRepository {
  @override
  Future<List<Match>> getMatches() async => [];
  @override
  Future<Match> getMatchById(String id) async => throw UnimplementedError();
  @override
  Future<void> createMatch(Match match) async {}
  @override
  Future<List<MatchRequest>> getMatchRequests({String? city}) async => [];
  @override
  Future<MatchRequest> createMatchRequest(String sport) async =>
      throw UnimplementedError();
  @override
  Future<void> cancelMatchRequest(String requestId) async {}
  @override
  Future<void> acceptMatch(String matchId) async {}
  @override
  Future<Match> getGame(String gameId) async => throw UnimplementedError();
  @override
  Future<void> submitResult(
    String gameId, {
    required int playerAGoals,
    required int playerBGoals,
    required int playerAAssists,
    required int playerBAssists,
  }) async {}
  @override
  Future<void> confirmResult(String gameId) async {}
  @override
  Future<void> disputeResult(String gameId) async {}
}

ProviderContainer makeContainer() => ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        matchRepositoryProvider.overrideWithValue(FakeMatchRepository()),
      ],
    );

void main() {
  group('matchListProvider', () {
    test('starts loading then resolves to empty list', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      expect(c.read(matchListProvider), isA<AsyncLoading<List<Match>>>());
      final matches = await c.read(matchListProvider.future);
      expect(matches, isEmpty);
      expect(c.read(matchListProvider), isA<AsyncData<List<Match>>>());
    });
  });
}
