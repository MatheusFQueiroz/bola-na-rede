import 'package:dio/dio.dart';

import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/auth/data/models/user_profile_model.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/profile/data/datasources/profile_mock_datasource.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/update_profile_input.dart';

class ProfileHttpDataSource implements ProfileDataSource {
  ProfileHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<PlayerProfile> getProfile(String userId) async {
    final res = await dio.get<Map<String, dynamic>>('/v1/users/me');
    return UserProfileModel.fromJson(
      res.data!['data'] as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<PlayerProfile> updateProfile(UpdateProfileInput input) async {
    final body = <String, dynamic>{
      'displayName': input.displayName,
      if (input.city != null) 'city': input.city,
      if (input.bio != null) 'bio': input.bio,
      if (input.position != null) 'position': _positionValue(input.position!),
      if (input.skillLevel != null) 'skillLevel': input.skillLevel,
      if (input.isPublic != null) 'isPublic': input.isPublic,
    };
    final res = await dio.put<Map<String, dynamic>>(
      '/v1/users/me/profile',
      data: body,
    );
    final payload = res.data!['data'] as Map<String, dynamic>? ?? res.data!;
    return UserProfileModel.fromJson(payload).toEntity();
  }

  static String _positionValue(PlayerPosition p) => switch (p) {
        PlayerPosition.goalkeeper => 'goalkeeper',
        PlayerPosition.defender => 'defender',
        PlayerPosition.midfielder => 'midfielder',
        PlayerPosition.forward => 'forward',
      };

  @override
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId) async {
    final res = await dio.get<Map<String, dynamic>>('/v1/games');
    final data = (res.data?['data'] as List<dynamic>?) ?? [];
    final completed = data
        .cast<Map<String, dynamic>>()
        .where((g) => (g['status'] as String? ?? '') == 'COMPLETED')
        .toList();
    final recent = completed.reversed.take(5).toList();
    return recent.map((g) {
      final sport = g['sport'] as String? ?? 'Jogo';
      final createdAt = DateTime.tryParse(
            g['createdAt'] as String? ?? '',
          ) ??
          DateTime.now();
      final day = createdAt.day.toString().padLeft(2, '0');
      final month = createdAt.month.toString().padLeft(2, '0');
      final year = createdAt.year;
      final dateFormatted = '$day/$month/$year';
      final winnerId = g['winnerId'] as String?;
      final String result;
      if (winnerId == null) {
        result = 'draw';
      } else if (winnerId == userId) {
        result = 'win';
      } else {
        result = 'loss';
      }
      return <String, dynamic>{
        'title': '$sport — $dateFormatted',
        'date': dateFormatted,
        'location': 'Arena',
        'result': result,
      };
    }).toList();
  }
}
