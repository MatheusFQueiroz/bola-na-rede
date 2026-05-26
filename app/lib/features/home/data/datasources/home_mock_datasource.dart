import '../../../match/domain/entities/match.dart';
import '../../../team/domain/entities/team.dart';
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/shared/snapshots.dart';

abstract class HomeDataSource {
  Future<Match?> getNextMatch(String teamId);
  Future<Match?> getPendingRequest(String teamId);
  Future<Team?> getMyTeam(String teamId);
}

class HomeMockDataSource implements HomeDataSource {
  @override
  Future<Match?> getNextMatch(String teamId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Match(
      id: 'match-001',
      proposalId: 'proposal-001',
      teamAId: 'team-001',
      teamBId: 'team-002',
      teamASnapshot: const TeamSnapshot(
        teamId: 'team-001',
        name: 'Furacao FC',
        city: 'Curitiba',
      ),
      teamBSnapshot: const TeamSnapshot(
        teamId: 'team-002',
        name: 'Uniao Vila',
        city: 'Curitiba',
      ),
      fieldId: 'field-001',
      fieldSnapshot: const FieldSnapshot(
        fieldId: 'field-001',
        name: 'Soccer Place',
        address: 'Rua das Araucarias, 450',
      ),
      scheduledDate: DateTime(2025, 7, 15),
      scheduledTimeStart: '18:00',
      scheduledTimeEnd: '19:00',
      status: MatchStatus.scheduled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Match?> getPendingRequest(String teamId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Match(
      id: 'match-pending',
      proposalId: 'proposal-pending',
      teamAId: 'team-003',
      teamBId: 'team-001',
      teamASnapshot: const TeamSnapshot(
        teamId: 'team-003',
        name: 'Dragoes da ZL',
        city: 'Curitiba',
      ),
      teamBSnapshot: const TeamSnapshot(
        teamId: 'team-001',
        name: 'Furacao FC',
        city: 'Curitiba',
      ),
      fieldId: 'field-001',
      fieldSnapshot: const FieldSnapshot(
        fieldId: 'field-001',
        name: 'Arena Sports',
        address: 'Rua das Araucarias, 450',
      ),
      scheduledDate: DateTime(2025, 7, 25),
      scheduledTimeStart: '19:00',
      scheduledTimeEnd: '20:00',
      status: MatchStatus.scheduled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Team?> getMyTeam(String teamId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Team(
      id: 'team-001',
      name: 'Furacao FC',
      city: 'Curitiba',
      status: TeamStatus.active,
      createdBy: 'user-001',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime.now(),
    );
  }
}
