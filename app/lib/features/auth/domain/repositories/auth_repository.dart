import '../entities/user.dart';

abstract class AuthRepository {
  Future<PlayerProfile> login(String email, String password);
  Future<PlayerProfile> register(String name, String email, String password);
  Future<void> logout();
  PlayerProfile? get currentUser;
}
