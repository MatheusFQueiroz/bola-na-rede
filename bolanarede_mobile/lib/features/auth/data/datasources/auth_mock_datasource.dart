import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';

abstract class AuthDataSource {
  Future<PlayerProfile> login(String email, String password);
  Future<PlayerProfile> register(
    String name,
    String email,
    String password, {
    String? position,
  });
  Future<PlayerProfile> restoreSession(String token);
}

class AuthMockDataSource implements AuthDataSource {
  PlayerProfile _fixedProfile(String displayName) => PlayerProfile(
        userId: 'user-001',
        displayName: displayName,
        photoUrl: null,
        bio: null,
        city: 'Curitiba',
        position: PlayerPosition.forward,
        skillLevel: SkillLevel.intermediate,
        isPublic: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime.now(),
      );

  @override
  Future<PlayerProfile> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (password.length < 6) {
      throw Exception('Senha deve ter pelo menos 6 caracteres');
    }

    // qualquer email/senha válida loga com usuário fixo
    return _fixedProfile(email.split('@').first);
  }

  @override
  Future<PlayerProfile> restoreSession(String token) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!token.startsWith('mock-token-')) {
      throw Exception('Sessão inválida');
    }

    return _fixedProfile('Jogador');
  }

  @override
  Future<PlayerProfile> register(
    String name,
    String email,
    String password, {
    String? position,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (name.isEmpty) throw Exception('Nome obrigatório');
    if (password.length < 6)
      throw Exception('Senha deve ter pelo menos 6 caracteres');

    return PlayerProfile(
      userId: 'user-001',
      displayName: name,
      photoUrl: null,
      bio: null,
      city: 'Curitiba',
      position: null,
      skillLevel: null,
      isPublic: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
