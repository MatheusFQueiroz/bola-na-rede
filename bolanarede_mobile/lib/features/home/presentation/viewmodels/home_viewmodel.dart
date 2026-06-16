import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/home/data/repositories/home_repository_provider.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/presentation/viewmodels/team_viewmodel.dart';

class HomeData {
  final Match? nextMatch;
  final Match? pendingRequest;
  final Team? myTeam;

  const HomeData({this.nextMatch, this.pendingRequest, this.myTeam});

  int get myRank => 3;
  int get playerCount => 6;
  int get winStreak => 8;
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
    return HomeData(
      nextMatch: results[0] as Match?,
      pendingRequest: results[1] as Match?,
      myTeam: results[2] as Team?,
    );
  }
}

final homeProvider = AsyncNotifierProvider<HomeVM, HomeData>(HomeVM.new);
