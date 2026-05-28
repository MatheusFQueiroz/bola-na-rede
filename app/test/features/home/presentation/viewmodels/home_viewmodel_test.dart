import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:bola_na_rede/features/home/data/repositories/home_repository_provider.dart';
import 'package:bola_na_rede/features/home/domain/repositories/home_repository.dart';
import 'package:bola_na_rede/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import '../../../../helpers/fake_repositories.dart';

class FakeHomeRepository implements HomeRepository {
  @override
  Future<Match?> getNextMatch(String teamId) async => null;
  @override
  Future<Match?> getPendingRequest(String teamId) async => null;
  @override
  Future<Team?> getMyTeam(String teamId) async => null;
}

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          homeRepositoryProvider.overrideWithValue(FakeHomeRepository()),
        ],
      );

  group('HomeViewModel', () {
    test('initial state is idle', () {
      final c = makeContainer();
      addTearDown(c.dispose);

      expect(c.read(homeViewModelProvider).status, HomeStatus.idle);
    });

    test('loadHome sets status to success with null data when repo returns null',
        () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(homeViewModelProvider.notifier).loadHome();

      expect(c.read(homeViewModelProvider).status, HomeStatus.success);
      expect(c.read(homeViewModelProvider).nextMatch, isNull);
    });
  });
}
