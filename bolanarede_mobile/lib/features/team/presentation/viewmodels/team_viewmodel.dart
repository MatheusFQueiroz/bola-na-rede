import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/team/data/repositories/team_repository_provider.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

class TeamListVM extends AsyncNotifier<List<Team>> {
  @override
  Future<List<Team>> build() =>
      ref.watch(teamRepositoryProvider).getTeams();
}

final teamListProvider =
    AsyncNotifierProvider<TeamListVM, List<Team>>(TeamListVM.new);

final teamDetailProvider = FutureProvider.family<Team, String>(
  (ref, id) => ref.read(teamRepositoryProvider).getTeamById(id),
);

final teamMembersProvider = FutureProvider.autoDispose.family<List<TeamMember>, String>(
  (ref, teamId) => ref.read(teamRepositoryProvider).getMembers(teamId),
);

final myTeamProvider = FutureProvider<Team?>((ref) async {
  final user = ref.watch(authViewModelProvider).value;
  if (user == null) return null;

  final teams = await ref.watch(teamRepositoryProvider).getTeams();
  for (final team in teams) {
    if (team.createdBy == user.userId) return team;
  }
  return null;
});
