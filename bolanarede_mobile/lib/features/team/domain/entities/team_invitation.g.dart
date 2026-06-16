// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamInvitation _$TeamInvitationFromJson(Map<String, dynamic> json) =>
    TeamInvitation(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      invitedUserId: json['invited_user_id'] as String,
      invitedBy: json['invited_by'] as String,
      status: $enumDecode(_$InvitationStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      respondedAt: json['responded_at'] == null
          ? null
          : DateTime.parse(json['responded_at'] as String),
    );

Map<String, dynamic> _$TeamInvitationToJson(TeamInvitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'team_id': instance.teamId,
      'invited_user_id': instance.invitedUserId,
      'invited_by': instance.invitedBy,
      'status': _$InvitationStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'responded_at': instance.respondedAt?.toIso8601String(),
    };

const _$InvitationStatusEnumMap = {
  InvitationStatus.pending: 'PENDING',
  InvitationStatus.accepted: 'ACCEPTED',
  InvitationStatus.rejected: 'REJECTED',
  InvitationStatus.expired: 'EXPIRED',
};

CaptaincyTransfer _$CaptaincyTransferFromJson(Map<String, dynamic> json) =>
    CaptaincyTransfer(
      teamId: json['team_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      transferredAt: DateTime.parse(json['transferred_at'] as String),
    );

Map<String, dynamic> _$CaptaincyTransferToJson(CaptaincyTransfer instance) =>
    <String, dynamic>{
      'team_id': instance.teamId,
      'from_user_id': instance.fromUserId,
      'to_user_id': instance.toUserId,
      'transferred_at': instance.transferredAt.toIso8601String(),
    };
