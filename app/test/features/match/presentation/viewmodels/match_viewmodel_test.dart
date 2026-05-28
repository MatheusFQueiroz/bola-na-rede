import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:bola_na_rede/features/match/data/repositories/match_repository_provider.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
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
}

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          matchRepositoryProvider.overrideWithValue(FakeMatchRepository()),
        ],
      );

  group('MatchViewModel', () {
    test('initial listStatus is idle with empty list', () {
      final c = makeContainer();
      addTearDown(c.dispose);

      final s = c.read(matchViewModelProvider);

      expect(s.listStatus, MatchLoadStatus.idle);
      expect(s.matches, isEmpty);
    });

    test('loadMatches sets listStatus to success', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(matchViewModelProvider.notifier).loadMatches();

      expect(c.read(matchViewModelProvider).listStatus, MatchLoadStatus.success);
    });
  });
}
