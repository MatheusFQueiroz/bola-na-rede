import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/auth/domain/repositories/auth_repository.dart';

PlayerProfile fakeProfile({String name = 'Test'}) => PlayerProfile(
      userId: 'u-1',
      displayName: name,
      isPublic: true,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

class FakeAuthRepository implements AuthRepository {
  @override
  Future<PlayerProfile> login(String email, String password) async {
    if (password.length < 6) throw Exception('Senha deve ter pelo menos 6 caracteres');
    return fakeProfile(name: email.split('@').first);
  }

  @override
  Future<PlayerProfile> register(
          String name, String email, String password) async =>
      fakeProfile(name: name);

  @override
  Future<void> logout() async {}

  @override
  PlayerProfile? get currentUser => null;
}
