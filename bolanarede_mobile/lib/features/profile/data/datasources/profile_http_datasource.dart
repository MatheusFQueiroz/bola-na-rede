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
    final res = await dio.get<List<dynamic>>('/v1/games');
    final data = res.data ?? [];
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
