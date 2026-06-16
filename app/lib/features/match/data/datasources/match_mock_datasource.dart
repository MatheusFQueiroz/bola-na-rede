import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/shared/snapshots.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_request.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_result.dart';

abstract class MatchDataSource {
  Future<List<Match>> getMatches();
  Future<Match> getMatchById(String id);
  Future<void> createMatch(Match match);
}

class MatchMockDataSource implements MatchDataSource {
  final List<Match> _matches = [
    Match(
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
        name: 'Arena Society Xaxim',
        address: 'Rua das Araucarias, 450',
      ),
      scheduledDate: DateTime(2025, 7, 15),
      scheduledTimeStart: '18:00',
      scheduledTimeEnd: '19:00',
      status: MatchStatus.scheduled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Match(
      id: 'match-002',
      proposalId: 'proposal-002',
      teamAId: 'team-001',
      teamBId: 'team-003',
      teamASnapshot: const TeamSnapshot(
        teamId: 'team-001',
        name: 'Furacao FC',
        city: 'Curitiba',
      ),
      teamBSnapshot: const TeamSnapshot(
        teamId: 'team-003',
        name: 'Dragoes da ZL',
        city: 'Curitiba',
      ),
      fieldId: 'field-002',
      fieldSnapshot: const FieldSnapshot(
        fieldId: 'field-002',
        name: 'Campo do Ze',
        address: 'Av. Pinheirinho, 200',
      ),
      scheduledDate: DateTime(2025, 7, 10),
      scheduledTimeStart: '20:00',
      scheduledTimeEnd: '21:00',
      status: MatchStatus.completed,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<Match>> getMatches() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_matches);
  }

  @override
  Future<Match> getMatchById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _matches.firstWhere(
      (m) => m.id == id,
      orElse: () => throw Exception('Match $id não encontrado'),
    );
  }

  @override
  Future<void> createMatch(Match match) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _matches.add(match);
  }
}
