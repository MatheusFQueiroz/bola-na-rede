import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

class TeamModel {
  const TeamModel({
    required this.id,
    required this.name,
    required this.captainUserId,
    required this.minPlayers,
    required this.maxPlayers,
    required this.memberCount,
    required this.isActive,
    required this.createdAt,
    this.description,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) => TeamModel(
        id: json['id'] as String,
        name: json['name'] as String,
        captainUserId: json['captainUserId'] as String? ?? '',
        minPlayers: json['minPlayers'] as int? ?? 5,
        maxPlayers: json['maxPlayers'] as int? ?? 11,
        memberCount: json['memberCount'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] as String,
        description: json['description'] as String?,
      );

  final String id;
  final String name;
  final String? description;
  final String captainUserId;
  final int minPlayers;
  final int maxPlayers;
  final int memberCount;
  final bool isActive;
  final String createdAt;

  Team toEntity() => Team(
        id: id,
        name: name,
        city: '',
        status: isActive ? TeamStatus.active : TeamStatus.inactive,
        createdBy: captainUserId,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(createdAt),
      );
}

class TeamMemberModel {
  const TeamMemberModel({
    required this.userId,
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) =>
      TeamMemberModel(
        userId: json['playerUserId'] as String,
        name: json['displayName'] as String? ?? '',
        role: json['role'] as String? ?? 'member',
        joinedAt: json['joinedAt'] as String,
      );

  final String userId;
  final String name;
  final String role;
  final String joinedAt;

  TeamMember toEntity() => TeamMember(
        teamId: '',
        userId: userId,
        role: role == 'captain'
            ? TeamMemberRole.captain
            : TeamMemberRole.member,
        joinedAt: DateTime.parse(joinedAt),
        displayName: name.isNotEmpty ? name : null,
      );
}
