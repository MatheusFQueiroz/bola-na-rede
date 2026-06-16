import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/peladas/data/datasources/open_game_datasource_provider.dart';
import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';

class OpenGameListVM extends AsyncNotifier<List<OpenGame>> {
  String? _sport;

  @override
  Future<List<OpenGame>> build() =>
      ref.watch(openGameRepositoryProvider).getOpenGames(sport: _sport);

  Future<void> filterBySport(String? sport) async {
    _sport = sport;
    ref.invalidateSelf();
  }

  Future<void> refresh() => update(
        (_) => ref.read(openGameRepositoryProvider).getOpenGames(sport: _sport),
      );
}

final openGameListProvider =
    AsyncNotifierProvider<OpenGameListVM, List<OpenGame>>(OpenGameListVM.new);

final openGameDetailProvider = FutureProvider.family<OpenGame, String>(
  (ref, id) => ref.read(openGameRepositoryProvider).getOpenGameById(id),
);

class CreateOpenGameVM extends AsyncNotifier<OpenGame?> {
  @override
  Future<OpenGame?> build() async => null;

  Future<OpenGame?> create({
    required String title,
    required String sport,
    required String scheduledAt,
    int? durationMinutes,
    int? minPlayers,
    int? maxPlayers,
    String? fieldId,
    String? description,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(openGameRepositoryProvider).createOpenGame(
            title: title,
            sport: sport,
            scheduledAt: scheduledAt,
            durationMinutes: durationMinutes,
            minPlayers: minPlayers,
            maxPlayers: maxPlayers,
            fieldId: fieldId,
            description: description,
          ),
    );
    state = result;
    return result.value;
  }
}

final createOpenGameProvider =
    AsyncNotifierProvider<CreateOpenGameVM, OpenGame?>(CreateOpenGameVM.new);
