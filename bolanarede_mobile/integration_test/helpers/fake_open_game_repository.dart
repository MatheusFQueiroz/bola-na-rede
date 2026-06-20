import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';
import 'package:bola_na_rede/features/peladas/domain/repositories/open_game_repository.dart';

class FakeOpenGameRepository implements OpenGameRepository {
  @override
  Future<List<OpenGame>> getOpenGames({String? sport}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return <OpenGame>[
      OpenGame(
        id: 'game-001',
        organizerUserId: 'user-001',
        title: 'Pelada da Tarde',
        sport: 'futsal',
        scheduledAt: now.add(const Duration(days: 1)),
        durationMinutes: 60,
        minPlayers: 10,
        maxPlayers: 12,
        status: 'open',
        participantCount: 5,
        fieldNameSnapshot: 'Arena Sports',
        fieldAddressSnapshot: 'Rua das Flores, 123',
        createdAt: now,
        updatedAt: now,
      ),
      OpenGame(
        id: 'game-002',
        organizerUserId: 'user-002',
        title: 'Rachao de Sexta',
        sport: 'society',
        scheduledAt: now.add(const Duration(days: 2)),
        durationMinutes: 90,
        minPlayers: 14,
        maxPlayers: 16,
        status: 'open',
        participantCount: 8,
        fieldNameSnapshot: 'Gramado Central',
        fieldAddressSnapshot: 'Av. das Palmeiras, 456',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  Future<OpenGame> getOpenGameById(String id) async {
    final games = await getOpenGames();
    return games.firstWhere((g) => g.id == id);
  }

  @override
  Future<OpenGame> createOpenGame({
    required String title,
    required String sport,
    required String scheduledAt,
    int? durationMinutes,
    int? minPlayers,
    int? maxPlayers,
    String? fieldId,
    String? description,
  }) async {
    final now = DateTime.now();
    return OpenGame(
      id: 'game-new',
      organizerUserId: 'user-001',
      title: title,
      sport: sport,
      scheduledAt: DateTime.parse(scheduledAt),
      durationMinutes: durationMinutes ?? 60,
      minPlayers: minPlayers ?? 10,
      maxPlayers: maxPlayers ?? 12,
      status: 'open',
      participantCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> joinOpenGame(String id) async {}

  @override
  Future<void> leaveOpenGame(String id) async {}

  @override
  Future<void> cancelOpenGame(String id) async {}
}
