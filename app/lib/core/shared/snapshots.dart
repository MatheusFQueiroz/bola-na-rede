import 'package:json_annotation/json_annotation.dart';

part 'snapshots.g.dart';

// Usado em: open_games.field_snapshot, matches.field_snapshot,
//           reservations (via booker_snapshot indireto)
// Origem: field-service (snapshottado na criação do evento)

@JsonSerializable()
class FieldSnapshot {
  @JsonKey(name: 'field_id')
  final String fieldId;

  final String name;
  final String? address;
  final double? lat;
  final double? lng;

  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  /// Usado quando o campo é livre (sem cadastro no catálogo)
  @JsonKey(name: 'free_address')
  final String? freeAddress;

  const FieldSnapshot({
    required this.fieldId,
    required this.name,
    this.address,
    this.lat,
    this.lng,
    this.photoUrl,
    this.freeAddress,
  });

  factory FieldSnapshot.fromJson(Map<String, dynamic> json) =>
      _$FieldSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$FieldSnapshotToJson(this);
}

// Usado em: open_games.organizer_snapshot
// Origem: identity-service (via JWT no momento da criação)

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

// Usado em: matches.team_a_snapshot, matches.team_b_snapshot
// Origem: team-service (snapshottado na aceitação do matchmaking)

@JsonSerializable()
class TeamSnapshot {
  @JsonKey(name: 'team_id')
  final String teamId;

  final String name;
  final String city;

  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  const TeamSnapshot({
    required this.teamId,
    required this.name,
    required this.city,
    this.logoUrl,
  });

  factory TeamSnapshot.fromJson(Map<String, dynamic> json) =>
      _$TeamSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$TeamSnapshotToJson(this);
}

// Usado em: reservations.booker_snapshot
// Origem: identity-service / team-service / open-game-service
// Representa quem fez a reserva (jogador individual, time ou grupo)

enum BookerType {
  @JsonValue('player')
  player,
  @JsonValue('team')
  team,
  @JsonValue('group')
  group,
}

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
    required this.type,
    this.photoUrl,
    this.contactPhone,
  });

  factory BookerSnapshot.fromJson(Map<String, dynamic> json) =>
      _$BookerSnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$BookerSnapshotToJson(this);
}
