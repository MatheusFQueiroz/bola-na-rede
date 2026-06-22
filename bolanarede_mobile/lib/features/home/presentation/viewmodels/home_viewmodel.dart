import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/home/data/repositories/home_repository_provider.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/ranking/data/repositories/ranking_repository_provider.dart';
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/presentation/viewmodels/team_viewmodel.dart';

class HomeData {
  const HomeData({
    this.nextMatch,
    this.pendingRequest,
    this.myTeam,
    this.myRank = 0,
    this.playerCount = 0,
    this.winStreak = 0,
  });

  final Match? nextMatch;
  final Match? pendingRequest;
  final Team? myTeam;
  final int myRank;
  final int playerCount;
  final int winStreak;
}

class HomeVM extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() async {
    final myTeam = await ref.watch(myTeamProvider.future);
    final teamId = myTeam?.id ?? '';
    final repo = ref.watch(homeRepositoryProvider);

    final results = await Future.wait([
      repo.getNextMatch(teamId),
      repo.getPendingRequest(teamId),
      repo.getMyTeam(teamId),
    ]);

    final resolvedTeam = results[2] as Team? ?? myTeam;

    var myRank = 0;
    try {
      final profile = ref.read(authViewModelProvider).value;
      if (profile != null) {
        final rankings =
            await ref.read(rankingRepositoryProvider).getPlayerRankings();
        final entry = rankings.cast<PlayerRanking?>().firstWhere(
              (r) => r?.id == profile.userId,
              orElse: () => null,
            );
        myRank = entry?.rank ?? 0;
      }
    } on Exception catch (_) {}

    return HomeData(
      nextMatch: results[0] as Match?,
      pendingRequest: results[1] as Match?,
      myTeam: resolvedTeam,
      myRank: myRank,
      playerCount: resolvedTeam?.memberCount ?? 0,
    );
  }
}

final homeProvider = AsyncNotifierProvider<HomeVM, HomeData>(HomeVM.new);
