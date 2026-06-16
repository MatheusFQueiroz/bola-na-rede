import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/team/data/datasources/team_mock_datasource.dart';
import 'package:bola_na_rede/features/team/data/models/team_model.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

class TeamHttpDataSource implements TeamDataSource {
  TeamHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<Team>> getTeams() async {
    final res = await dio.get<List<dynamic>>('/v1/teams');
    final data = res.data ?? [];
    return data
        .map((e) => TeamModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<Team> getTeamById(String id) async {
    final res = await dio.get<Map<String, dynamic>>('/v1/teams/$id');
    return TeamModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<Team> createTeam({
    required String name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/v1/teams',
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (minPlayers != null) 'minPlayers': minPlayers,
        if (maxPlayers != null) 'maxPlayers': maxPlayers,
      },
    );
    return TeamModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<List<TeamMember>> getMembers(String teamId) async {
    final res =
        await dio.get<List<dynamic>>('/v1/teams/$teamId/members');
    final data = res.data ?? [];
    return data
        .map(
          (e) =>
              TeamMemberModel.fromJson(e as Map<String, dynamic>).toEntity(),
        )
        .toList();
  }

  @override
  Future<void> joinTeam(String teamId) =>
      dio.post<void>('/v1/teams/$teamId/members');

  @override
  Future<void> leaveTeam(String teamId) =>
      dio.delete<void>('/v1/teams/$teamId/members/me');

  @override
  Future<void> removeMember(String teamId, String userId) =>
      dio.delete<void>('/v1/teams/$teamId/members/$userId');
}
