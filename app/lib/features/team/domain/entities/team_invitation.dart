import 'package:json_annotation/json_annotation.dart';

import 'package:bola_na_rede/core/shared/enums.dart';

part 'team_invitation.g.dart';

// ---------------------------------------------------------------------------
// TeamInvitation
// Tabela: team-service → team_invitations
// Somente o CAPTAIN pode enviar convites (RN03)
// ---------------------------------------------------------------------------

@JsonSerializable()
class TeamInvitation {
  final String id;

  @JsonKey(name: 'team_id')
  final String teamId;

  /// = users.external_id do convidado
  @JsonKey(name: 'invited_user_id')
  final String invitedUserId;

  /// = users.external_id do capitão que convidou
  @JsonKey(name: 'invited_by')
  final String invitedBy;

  final InvitationStatus status;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  @JsonKey(name: 'responded_at')
  final DateTime? respondedAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  const TeamInvitation({
    required this.id,
    required this.teamId,
    required this.invitedUserId,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) =>
      _$TeamInvitationFromJson(json);

  Map<String, dynamic> toJson() => _$TeamInvitationToJson(this);
}

// ---------------------------------------------------------------------------
// CaptaincyTransfer
// Tabela: team-service → captaincy_transfers
// Audit trail — RN10
// ---------------------------------------------------------------------------

@JsonSerializable()
class CaptaincyTransfer {
  @JsonKey(name: 'team_id')
  final String teamId;

  @JsonKey(name: 'from_user_id')
  final String fromUserId;

  @JsonKey(name: 'to_user_id')
  final String toUserId;

  @JsonKey(name: 'transferred_at')
  final DateTime transferredAt;

  const CaptaincyTransfer({
    required this.teamId,
    required this.fromUserId,
    required this.toUserId,
    required this.transferredAt,
  });

  factory CaptaincyTransfer.fromJson(Map<String, dynamic> json) =>
      _$CaptaincyTransferFromJson(json);

  Map<String, dynamic> toJson() => _$CaptaincyTransferToJson(this);
}
