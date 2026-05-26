import '../../domain/entities/team.dart';
import 'package:bola_na_rede/core/shared/enums.dart';

abstract class TeamDataSource {
  Future<List<Team>> getTeams();
  Future<Team> getTeamById(String id);
}

class TeamMockDataSource implements TeamDataSource {
  static final _teams = [
    Team(
      id: 'team-001',
      name: 'Furacao FC',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-001',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 6, 1),
    ),
    Team(
      id: 'team-002',
      name: 'Uniao Vila',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-002',
      createdAt: DateTime(2024, 2, 1),
      updatedAt: DateTime(2024, 6, 1),
    ),
    Team(
      id: 'team-003',
      name: 'Dragoes da ZL',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-003',
      createdAt: DateTime(2024, 3, 1),
      updatedAt: DateTime(2024, 6, 1),
    ),
    Team(
      id: 'team-004',
      name: 'Leoes FC',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-004',
      createdAt: DateTime(2024, 4, 1),
      updatedAt: DateTime(2024, 6, 1),
    ),
    Team(
      id: 'team-005',
      name: 'Rapidos SC',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-005',
      createdAt: DateTime(2024, 5, 1),
      updatedAt: DateTime(2024, 6, 1),
    ),
  ];

  @override
  Future<List<Team>> getTeams() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_teams);
  }

  @override
  Future<Team> getTeamById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _teams.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception('Team $id não encontrado'),
    );
  }
}
