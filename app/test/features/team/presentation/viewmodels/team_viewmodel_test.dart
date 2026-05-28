import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/team/data/repositories/team_repository_provider.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/domain/repositories/team_repository.dart';
import 'package:bola_na_rede/features/team/presentation/viewmodels/team_viewmodel.dart';

class FakeTeamRepository implements TeamRepository {
  @override
  Future<List<Team>> getTeams() async => [];
  @override
  Future<Team> getTeamById(String id) async => throw UnimplementedError();
}

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          teamRepositoryProvider.overrideWithValue(FakeTeamRepository()),
        ],
      );

  group('TeamViewModel', () {
    test('initial state is idle with empty list', () {
      final c = makeContainer();
      addTearDown(c.dispose);

      expect(c.read(teamViewModelProvider).status, TeamStatus.idle);
      expect(c.read(teamViewModelProvider).teams, isEmpty);
    });

    test('loadTeams sets status to success', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(teamViewModelProvider.notifier).loadTeams();

      expect(c.read(teamViewModelProvider).status, TeamStatus.success);
    });
  });
}
