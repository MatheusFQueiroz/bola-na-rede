import '../../../match/domain/entities/match.dart';
import '../../../team/domain/entities/team.dart';
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/shared/snapshots.dart';

abstract class SearchDataSource {
  Future<List<Match>> searchMatches(String query);
  Future<List<Team>> searchTeams(String query);
}

class SearchMockDataSource implements SearchDataSource {
  static final _matches = [
    Match(
      id: 'match-s001',
      proposalId: 'proposal-s001',
      teamAId: 'team-001',
      teamBId: 'team-tbd',
      teamASnapshot: const TeamSnapshot(
        teamId: 'team-001',
        name: 'Furacao FC',
        city: 'Curitiba',
      ),
      fieldSnapshot: const FieldSnapshot(
        fieldId: 'field-001',
        name: 'Arena Society Xaxim',
        address: 'Xaxim, Curitiba',
      ),
      scheduledDate: DateTime(2025, 7, 15),
      scheduledTimeStart: '18:00',
      scheduledTimeEnd: '19:00',
      status: MatchStatus.scheduled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Match(
      id: 'match-s002',
      proposalId: 'proposal-s002',
      teamAId: 'team-004',
      teamBId: 'team-tbd',
      teamASnapshot: const TeamSnapshot(
        teamId: 'team-004',
        name: 'Leoes FC',
        city: 'Curitiba',
      ),
      fieldSnapshot: const FieldSnapshot(
        fieldId: 'field-002',
        name: 'Campo do Ze',
        address: 'Pinheirinho, Curitiba',
      ),
      scheduledDate: DateTime(2025, 7, 13),
      scheduledTimeStart: '20:00',
      scheduledTimeEnd: '21:00',
      status: MatchStatus.scheduled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Match(
      id: 'match-s003',
      proposalId: 'proposal-s003',
      teamAId: 'team-005',
      teamBId: 'team-tbd',
      teamASnapshot: const TeamSnapshot(
        teamId: 'team-005',
        name: 'Rapidos SC',
        city: 'Curitiba',
      ),
      fieldSnapshot: const FieldSnapshot(
        fieldId: 'field-003',
        name: 'Futsal Center Portao',
        address: 'Portao, Curitiba',
      ),
      scheduledDate: DateTime(2025, 7, 18),
      scheduledTimeStart: '19:00',
      scheduledTimeEnd: '20:00',
      status: MatchStatus.scheduled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  static final _teams = [
    Team(
      id: 'team-003',
      name: 'Dragoes da ZL',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-003',
      createdAt: DateTime(2024, 3, 1),
      updatedAt: DateTime.now(),
    ),
    Team(
      id: 'team-004',
      name: 'Leoes FC',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-004',
      createdAt: DateTime(2024, 4, 1),
      updatedAt: DateTime.now(),
    ),
    Team(
      id: 'team-005',
      name: 'Rapidos SC',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-005',
      createdAt: DateTime(2024, 5, 1),
      updatedAt: DateTime.now(),
    ),
    Team(
      id: 'team-006',
      name: 'Trovoes',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-006',
      createdAt: DateTime(2024, 6, 1),
      updatedAt: DateTime.now(),
    ),
    Team(
      id: 'team-007',
      name: 'Estrelas',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-007',
      createdAt: DateTime(2024, 7, 1),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<Match>> searchMatches(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (query.isEmpty) return List.from(_matches);
    return _matches.where((m) {
      final teamName = m.teamASnapshot?.name.toLowerCase() ?? '';
      final fieldName = m.fieldSnapshot?.name.toLowerCase() ?? '';
      final q = query.toLowerCase();
      return teamName.contains(q) || fieldName.contains(q);
    }).toList();
  }

  @override
  Future<List<Team>> searchTeams(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (query.isEmpty) return List.from(_teams);
    return _teams.where((t) {
      final q = query.toLowerCase();
      return t.name.toLowerCase().contains(q) ||
          t.city.toLowerCase().contains(q);
    }).toList();
  }
}
