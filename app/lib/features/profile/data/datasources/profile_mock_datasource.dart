import '../../../auth/domain/entities/user.dart';
import 'package:bola_na_rede/core/shared/enums.dart';

abstract class ProfileDataSource {
  Future<PlayerProfile> getProfile(String userId);
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId);
}

class ProfileMockDataSource implements ProfileDataSource {
  @override
  Future<PlayerProfile> getProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return PlayerProfile(
      userId: userId,
      displayName: 'Carlos Souza',
      photoUrl: null,
      bio: 'Jogador desde 2018. Capitão do Furacao FC.',
      city: 'Curitiba',
      position: PlayerPosition.forward,
      skillLevel: SkillLevel.intermediate,
      isPublic: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {
        'title': 'FU 3 x 1 UN',
        'location': 'Soccer Place',
        'date': '15/03',
        'result': 'win',
      },
      {
        'title': 'FU 2 x 2 D2',
        'location': 'Arena Xaxim',
        'date': '10/03',
        'result': 'draw',
      },
      {
        'title': 'FU 0 x 1 RS',
        'location': 'Campo do Ze',
        'date': '05/03',
        'result': 'loss',
      },
    ];
  }
}
