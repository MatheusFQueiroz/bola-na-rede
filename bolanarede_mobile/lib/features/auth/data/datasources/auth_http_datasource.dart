import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:bola_na_rede/features/auth/data/datasources/token_storage.dart';
import 'package:bola_na_rede/features/auth/data/models/auth_response_model.dart';
import 'package:bola_na_rede/features/auth/data/models/user_profile_model.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';

class AuthHttpDataSource implements AuthDataSource {
  AuthHttpDataSource({required this.dio, required this.tokenStorage});

  final Dio dio;
  final TokenStorage tokenStorage;

  @override
  Future<PlayerProfile> login(String email, String password) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/v1/auth/login',
      data: {'email': email, 'password': password},
    );
    final auth = AuthResponseModel.fromJson(res.data!);
    await tokenStorage.saveToken(auth.accessToken);
    return _fetchProfile();
  }

  @override
  Future<PlayerProfile> register(
    String name,
    String email,
    String password, {
    String? position,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/v1/auth/register',
      data: {
        'email': email,
        'password': password,
        'displayName': name,
        if (position != null) 'position': position,
      },
    );
    final auth = AuthResponseModel.fromJson(res.data!);
    await tokenStorage.saveToken(auth.accessToken);
    return _fetchProfile();
  }

  @override
  Future<PlayerProfile> restoreSession(String token) => _fetchProfile();

  Future<PlayerProfile> _fetchProfile() async {
    final res = await dio.get<Map<String, dynamic>>('/v1/users/me');
    return UserProfileModel.fromJson(
      res.data!['data'] as Map<String, dynamic>,
    ).toEntity();
  }
}
