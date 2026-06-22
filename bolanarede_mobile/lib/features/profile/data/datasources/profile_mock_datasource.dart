import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/update_profile_input.dart';

abstract class ProfileDataSource {
  Future<PlayerProfile> getProfile(String userId);
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId);
  Future<PlayerProfile> updateProfile(UpdateProfileInput input);
}

class ProfileMockDataSource implements ProfileDataSource {
  @override
  Future<PlayerProfile> getProfile(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
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
  Future<PlayerProfile> updateProfile(UpdateProfileInput input) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final skillLevel = input.skillLevel != null
        ? _parseSkillLevel(input.skillLevel!)
        : null;
    return PlayerProfile(
      userId: 'user-001',
      displayName: input.displayName,
      photoUrl: null,
      bio: input.bio,
      city: input.city,
      position: input.position,
      skillLevel: skillLevel,
      isPublic: input.isPublic ?? true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime.now(),
    );
  }

  static SkillLevel? _parseSkillLevel(int raw) => switch (raw) {
        1 => SkillLevel.beginner,
        2 => SkillLevel.recreational,
        3 => SkillLevel.intermediate,
        4 => SkillLevel.advanced,
        5 => SkillLevel.competitive,
        _ => null,
      };

  @override
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
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
