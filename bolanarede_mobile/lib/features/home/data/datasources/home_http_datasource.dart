import 'package:dio/dio.dart';

import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/home/data/datasources/home_mock_datasource.dart';
import 'package:bola_na_rede/features/match/data/models/game_model.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/team/data/models/team_model.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

class HomeHttpDataSource implements HomeDataSource {
  const HomeHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<Match?> getNextMatch(String teamId) async {
    if (teamId.isEmpty) return null;
    final response = await dio.get<Map<String, dynamic>>('/v1/games');
    final list = (response.data?['data'] as List<dynamic>?) ?? [];
    final now = DateTime.now();
    for (final item in list) {
      final match =
          GameModel.fromJson(item as Map<String, dynamic>).toEntity();
      if (match.status == MatchStatus.scheduled &&
          match.scheduledDate.isAfter(now) &&
          (match.teamAId == teamId || match.teamBId == teamId)) {
        return match;
      }
    }
    return null;
  }

  @override
  Future<Match?> getPendingRequest(String teamId) async {
    final response =
        await dio.get<Map<String, dynamic>>('/v1/match-requests');
    final list = (response.data?['data'] as List<dynamic>?) ?? [];
    for (final item in list) {
      final json = item as Map<String, dynamic>;
      if ((json['status'] as String? ?? '') == 'pending') {
        final createdAt = DateTime.tryParse(
              json['createdAt'] as String? ?? '',
            ) ??
            DateTime.now();
        return Match(
          id: json['id'] as String? ?? '',
          proposalId: '',
          teamAId: json['requesterUserId'] as String? ?? '',
          teamBId: teamId,
          scheduledDate: createdAt,
          scheduledTimeStart: '',
          scheduledTimeEnd: '',
          status: MatchStatus.scheduled,
          createdAt: createdAt,
          updatedAt: createdAt,
          sport: json['sport'] as String?,
        );
      }
    }
    return null;
  }

  @override
  Future<Team?> getMyTeam(String teamId) async {
    if (teamId.isEmpty) return null;
    final response =
        await dio.get<Map<String, dynamic>>('/v1/teams/$teamId');
    return TeamModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toEntity();
  }
}
