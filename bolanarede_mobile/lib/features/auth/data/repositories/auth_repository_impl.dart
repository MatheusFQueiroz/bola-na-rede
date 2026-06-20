import 'package:bola_na_rede/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;
  PlayerProfile? _currentUser;

  AuthRepositoryImpl({required this.dataSource});

  @override
  PlayerProfile? get currentUser => _currentUser;

  @override
  Future<PlayerProfile> login(String email, String password) async {
    _currentUser = await dataSource.login(email, password);
    return _currentUser!;
  }

  @override
  Future<PlayerProfile> register(
    String name,
    String email,
    String password, {
    String? position,
  }) async {
    _currentUser = await dataSource.register(
      name,
      email,
      password,
      position: position,
    );
    return _currentUser!;
  }

  @override
  Future<PlayerProfile> restoreSession(String token) async {
    _currentUser = await dataSource.restoreSession(token);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }
}
