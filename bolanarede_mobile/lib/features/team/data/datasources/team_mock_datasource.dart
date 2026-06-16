import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

abstract class TeamDataSource {
  Future<List<Team>> getTeams();
  Future<Team> getTeamById(String id);
  Future<Team> createTeam({
    required String name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
  });
  Future<List<TeamMember>> getMembers(String teamId);
  Future<void> joinTeam(String teamId);
  Future<void> leaveTeam(String teamId);
  Future<void> removeMember(String teamId, String userId);
}

class TeamMockDataSource implements TeamDataSource {
  static final _teams = [
    Team(
      id: 'team-001',
      name: 'Furacao FC',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-001',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024, 6),
    ),
    Team(
      id: 'team-002',
      name: 'Uniao Vila',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-002',
      createdAt: DateTime(2024, 2),
      updatedAt: DateTime(2024, 6),
    ),
    Team(
      id: 'team-003',
      name: 'Dragoes da ZL',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-003',
      createdAt: DateTime(2024, 3),
      updatedAt: DateTime(2024, 6),
    ),
    Team(
      id: 'team-004',
      name: 'Leoes FC',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-004',
      createdAt: DateTime(2024, 4),
      updatedAt: DateTime(2024, 6),
    ),
    Team(
      id: 'team-005',
      name: 'Rapidos SC',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-005',
      createdAt: DateTime(2024, 5),
      updatedAt: DateTime(2024, 6),
    ),
  ];

  @override
  Future<List<Team>> getTeams() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.from(_teams);
  }

  @override
  Future<Team> getTeamById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _teams.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception('Team $id não encontrado'),
    );
  }

  @override
  Future<Team> createTeam({
    required String name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _teams.first;
  }

  @override
  Future<List<TeamMember>> getMembers(String teamId) async => [];

  @override
  Future<void> joinTeam(String teamId) async {}

  @override
  Future<void> leaveTeam(String teamId) async {}

  @override
  Future<void> removeMember(String teamId, String userId) async {}
}
