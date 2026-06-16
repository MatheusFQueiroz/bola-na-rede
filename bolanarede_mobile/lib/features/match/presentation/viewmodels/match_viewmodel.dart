import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/shared/snapshots.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/match/data/repositories/match_repository_provider.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/team/presentation/viewmodels/team_viewmodel.dart';

class MatchListVM extends AsyncNotifier<List<Match>> {
  @override
  Future<List<Match>> build() =>
      ref.watch(matchRepositoryProvider).getMatches();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(matchRepositoryProvider).getMatches(),
    );
  }
}

final matchListProvider =
    AsyncNotifierProvider<MatchListVM, List<Match>>(MatchListVM.new);


final matchDetailProvider = FutureProvider.family<Match, String>(
  (ref, id) => ref.read(matchRepositoryProvider).getMatchById(id),
);


class CreateMatchVM extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required String teamBId,
    required String teamBName,
    required String teamBCity,
    required DateTime scheduledDate,
    required String timeStart,
    required String timeEnd,
    String? fieldId,
    String? fieldName,
    String? fieldAddress,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final user = ref.read(authViewModelProvider).value;
      final myTeam = await ref.read(myTeamProvider.future);
      final teamAId = myTeam?.id ?? '';
      final teamAName = myTeam?.name ?? user?.displayName ?? 'Meu Time';

      final newMatch = Match(
        id: const Uuid().v4(),
        proposalId: const Uuid().v4(),
        teamAId: teamAId,
        teamBId: teamBId,
        teamASnapshot: TeamSnapshot(
          teamId: teamAId,
          name: teamAName,
          city: myTeam?.city ?? user?.city ?? 'Curitiba',
        ),
        teamBSnapshot:
            TeamSnapshot(teamId: teamBId, name: teamBName, city: teamBCity),
        fieldId: fieldId,
        fieldSnapshot: fieldId != null
            ? FieldSnapshot(
                fieldId: fieldId,
                name: fieldName ?? 'Campo',
                address: fieldAddress,
              )
            : null,
        scheduledDate: scheduledDate,
        scheduledTimeStart: timeStart,
        scheduledTimeEnd: timeEnd,
        status: MatchStatus.scheduled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(matchRepositoryProvider).createMatch(newMatch);
      await ref.read(matchListProvider.notifier).refresh();
    });
    state = result;
    return !result.hasError;
  }
}

final createMatchProvider =
    AsyncNotifierProvider<CreateMatchVM, void>(CreateMatchVM.new);
