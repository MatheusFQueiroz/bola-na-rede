import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/auth/data/models/user_profile_model.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/profile/data/datasources/profile_mock_datasource.dart';

class ProfileHttpDataSource implements ProfileDataSource {
  ProfileHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<PlayerProfile> getProfile(String userId) async {
    final res = await dio.get<Map<String, dynamic>>('/v1/users/me');
    return UserProfileModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId) async {
    return [];
  }
}
