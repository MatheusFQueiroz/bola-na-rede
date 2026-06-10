// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snapshots.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookerSnapshot _$BookerSnapshotFromJson(Map<String, dynamic> json) =>
    BookerSnapshot(
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String?,
      type: $enumDecode(_$BookerTypeEnumMap, json['type']),
      contactPhone: json['contact_phone'] as String?,
    );

Map<String, dynamic> _$BookerSnapshotToJson(BookerSnapshot instance) =>
    <String, dynamic>{
      'name': instance.name,
      'photo_url': instance.photoUrl,
      'type': _$BookerTypeEnumMap[instance.type]!,
      'contact_phone': instance.contactPhone,
    };

const _$BookerTypeEnumMap = {
  BookerType.player: 'player',
  BookerType.team: 'team',
  BookerType.group: 'group',
};

OrganizerSnapshot _$OrganizerSnapshotFromJson(Map<String, dynamic> json) =>
    OrganizerSnapshot(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      photoUrl: json['photo_url'] as String?,
    );

Map<String, dynamic> _$OrganizerSnapshotToJson(OrganizerSnapshot instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'photo_url': instance.photoUrl,
    };
