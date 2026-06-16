import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';

abstract class OpenGameRepository {
  Future<List<OpenGame>> getOpenGames({String? sport});
  Future<OpenGame> getOpenGameById(String id);
  Future<OpenGame> createOpenGame({
    required String title,
    required String sport,
    required String scheduledAt,
    int? durationMinutes,
    int? minPlayers,
    int? maxPlayers,
    String? fieldId,
    String? description,
  });
  Future<void> joinOpenGame(String id);
  Future<void> leaveOpenGame(String id);
  Future<void> cancelOpenGame(String id);
}
