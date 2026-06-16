import 'package:json_annotation/json_annotation.dart';

part 'snapshots.g.dart';

@JsonSerializable()
class BookerSnapshot {
  final String name;

  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  final BookerType type;

  @JsonKey(name: 'contact_phone')
  final String? contactPhone;

  const BookerSnapshot({
    required this.name,
    this.photoUrl,
    required this.type,
    this.contactPhone,
  });

  factory BookerSnapshot.fromJson(Map<String, dynamic> json) =>
      _$BookerSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$BookerSnapshotToJson(this);
}

enum BookerType {
  @JsonValue('player')
  player,
  @JsonValue('team')
  team,
  @JsonValue('group')
  group,
}

@JsonSerializable()
class OrganizerSnapshot {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'display_name')
  final String displayName;

  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  const OrganizerSnapshot({
    required this.userId,
    required this.displayName,
    this.photoUrl,
  });

  factory OrganizerSnapshot.fromJson(Map<String, dynamic> json) =>
      _$OrganizerSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$OrganizerSnapshotToJson(this);
}
