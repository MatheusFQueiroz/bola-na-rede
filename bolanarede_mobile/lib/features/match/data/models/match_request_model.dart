import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_request.dart';

class MatchRequestModel {
  const MatchRequestModel({
    required this.id,
    required this.requesterUserId,
    required this.sport,
    required this.status,
    required this.requestedAt,
    required this.expiresAt,
    required this.displayName,
  });

  factory MatchRequestModel.fromJson(Map<String, dynamic> json) =>
      MatchRequestModel(
        id: json['id'] as String,
        requesterUserId: json['requesterUserId'] as String? ?? '',
        sport: json['sport'] as String? ?? 'football',
        status: json['status'] as String? ?? 'PENDING',
        requestedAt: json['requestedAt'] as String,
        expiresAt: json['expiresAt'] as String,
        displayName: json['displayName'] as String? ?? '',
      );

  final String id;
  final String requesterUserId;
  final String displayName;
  final String sport;
  final String status;
  final String requestedAt;
  final String expiresAt;

  MatchRequest toEntity() {
    final createdAt = DateTime.parse(requestedAt);
    final expires = DateTime.parse(expiresAt);
    return MatchRequest(
      id: id,
      requestingTeamId: requesterUserId,
      preferredDate: createdAt,
      preferredTimeStart: '',
      preferredTimeEnd: '',
      preferredCity: '',
      locationRangeKm: 0,
      status: _parseStatus(status),
      createdAt: createdAt,
      expiresAt: expires,
      updatedAt: createdAt,
    );
  }

  static MatchRequestStatus _parseStatus(String raw) => switch (raw) {
        'MATCHED' => MatchRequestStatus.matched,
        'EXPIRED' => MatchRequestStatus.expired,
        'CANCELLED' => MatchRequestStatus.cancelled,
        _ => MatchRequestStatus.pending,
      };
}
