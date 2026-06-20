import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/match/data/repositories/match_repository_provider.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';

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
  (ref, id) => ref.read(matchRepositoryProvider).getGame(id),
);

class CreateMatchRequestVM extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit(String sport) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(matchRepositoryProvider).createMatchRequest(sport),
    );
    state = result;
    return !result.hasError;
  }
}

final createMatchRequestProvider =
    AsyncNotifierProvider<CreateMatchRequestVM, void>(
        CreateMatchRequestVM.new);

class SubmitResultVM extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit(
    String gameId, {
    required int playerAGoals,
    required int playerBGoals,
    required int playerAAssists,
    required int playerBAssists,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(matchRepositoryProvider).submitResult(
            gameId,
            playerAGoals: playerAGoals,
            playerBGoals: playerBGoals,
            playerAAssists: playerAAssists,
            playerBAssists: playerBAssists,
          ),
    );
    state = result;
    if (!result.hasError) {
      ref.invalidate(matchDetailProvider(gameId));
      ref.invalidate(matchListProvider);
    }
    return !result.hasError;
  }
}

final submitResultProvider =
    AsyncNotifierProvider<SubmitResultVM, void>(SubmitResultVM.new);

final confirmResultProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, gameId) =>
      ref.read(matchRepositoryProvider).confirmResult(gameId),
);

final disputeResultProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, gameId) =>
      ref.read(matchRepositoryProvider).disputeResult(gameId),
);
