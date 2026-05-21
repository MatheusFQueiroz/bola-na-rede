// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snapshots.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FieldSnapshot _$FieldSnapshotFromJson(Map<String, dynamic> json) =>
    FieldSnapshot(
      fieldId: json['field_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      photoUrl: json['photo_url'] as String?,
      freeAddress: json['free_address'] as String?,
    );

Map<String, dynamic> _$FieldSnapshotToJson(FieldSnapshot instance) =>
    <String, dynamic>{
      'field_id': instance.fieldId,
      'name': instance.name,
      'address': instance.address,
      'lat': instance.lat,
      'lng': instance.lng,
      'photo_url': instance.photoUrl,
      'free_address': instance.freeAddress,
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

TeamSnapshot _$TeamSnapshotFromJson(Map<String, dynamic> json) => TeamSnapshot(
      teamId: json['team_id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      logoUrl: json['logo_url'] as String?,
    );

Map<String, dynamic> _$TeamSnapshotToJson(TeamSnapshot instance) =>
    <String, dynamic>{
      'team_id': instance.teamId,
      'name': instance.name,
      'city': instance.city,
      'logo_url': instance.logoUrl,
    };

BookerSnapshot _$BookerSnapshotFromJson(Map<String, dynamic> json) =>
    BookerSnapshot(
      name: json['name'] as String,
      type: $enumDecode(_$BookerTypeEnumMap, json['type']),
      photoUrl: json['photo_url'] as String?,
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
