import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';

class OpenGameModel {
  const OpenGameModel({
    required this.id,
    required this.organizerUserId,
    required this.title,
    required this.sport,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.minPlayers,
    required this.maxPlayers,
    required this.status,
    required this.participantCount,
    required this.createdAt,
    required this.updatedAt,
    this.fieldId,
    this.fieldNameSnapshot,
    this.fieldAddressSnapshot,
    this.description,
    this.pricePerPlayer,
  });

  factory OpenGameModel.fromJson(Map<String, dynamic> json) => OpenGameModel(
        id: json['id'] as String,
        organizerUserId: json['organizerUserId'] as String? ?? '',
        title: json['title'] as String,
        sport: json['sport'] as String? ?? 'futsal',
        scheduledAt: json['scheduledAt'] as String,
        durationMinutes: json['durationMinutes'] as int? ?? 60,
        minPlayers: json['minPlayers'] as int? ?? 10,
        maxPlayers: json['maxPlayers'] as int? ?? 22,
        status: json['status'] as String? ?? 'open',
        participantCount: json['participantCount'] as int? ?? 0,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
        fieldId: json['fieldId'] as String?,
        fieldNameSnapshot: json['fieldNameSnapshot'] as String?,
        fieldAddressSnapshot: json['fieldAddressSnapshot'] as String?,
        description: json['description'] as String?,
        pricePerPlayer: json['pricePerPlayer'] as num?,
      );

  final String id;
  final String organizerUserId;
  final String? fieldId;
  final String? fieldNameSnapshot;
  final String? fieldAddressSnapshot;
  final String title;
  final String? description;
  final String sport;
  final String scheduledAt;
  final int durationMinutes;
  final int minPlayers;
  final int maxPlayers;
  final num? pricePerPlayer;
  final String status;
  final int participantCount;
  final String createdAt;
  final String updatedAt;

  OpenGame toEntity() => OpenGame(
        id: id,
        organizerUserId: organizerUserId,
        title: title,
        sport: sport,
        scheduledAt: DateTime.parse(scheduledAt),
        durationMinutes: durationMinutes,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        status: status,
        participantCount: participantCount,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        fieldId: fieldId,
        fieldNameSnapshot: fieldNameSnapshot,
        fieldAddressSnapshot: fieldAddressSnapshot,
        description: description,
        pricePerPlayer: pricePerPlayer,
      );
}
