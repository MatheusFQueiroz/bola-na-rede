class OpenGame {
  const OpenGame({
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

  final String id;
  final String organizerUserId;
  final String? fieldId;
  final String? fieldNameSnapshot;
  final String? fieldAddressSnapshot;
  final String title;
  final String? description;
  final String sport;
  final DateTime scheduledAt;
  final int durationMinutes;
  final int minPlayers;
  final int maxPlayers;
  final num? pricePerPlayer;
  final String status;
  final int participantCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen => status == 'open';
  bool get isFull => participantCount >= maxPlayers;
}
