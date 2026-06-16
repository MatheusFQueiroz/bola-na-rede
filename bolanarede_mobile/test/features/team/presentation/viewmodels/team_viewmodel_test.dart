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

ProviderContainer makeContainer() => ProviderContainer(
      overrides: [
        teamRepositoryProvider.overrideWithValue(FakeTeamRepository()),
      ],
    );

void main() {
  group('teamListProvider', () {
    test('starts loading then resolves to empty list', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      expect(c.read(teamListProvider), isA<AsyncLoading<List<Team>>>());
      final teams = await c.read(teamListProvider.future);
      expect(teams, isEmpty);
    });
  });
}
