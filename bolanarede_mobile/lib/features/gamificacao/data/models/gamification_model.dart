import 'package:bola_na_rede/features/gamificacao/domain/entities/player_gamification.dart';

class BadgeModel {
  const BadgeModel({required this.badgeCode, required this.earnedAt});

  factory BadgeModel.fromJson(Map<String, dynamic> json) => BadgeModel(
        badgeCode: json['badgeCode'] as String,
        earnedAt: DateTime.parse(json['earnedAt'] as String),
      );

  final String badgeCode;
  final DateTime earnedAt;

  Badge toEntity() => Badge(code: badgeCode, earnedAt: earnedAt);
}

class GamificationModel {
  const GamificationModel({
    required this.playerUserId,
    required this.displayName,
    required this.totalXp,
    required this.level,
    required this.badges,
    required this.updatedAt,
  });

  factory GamificationModel.fromJson(Map<String, dynamic> json) =>
      GamificationModel(
        playerUserId: json['playerUserId'] as String,
        displayName: json['displayName'] as String,
        totalXp: json['totalXp'] as int,
        level: json['level'] as int,
        badges: (json['badges'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(BadgeModel.fromJson)
            .toList(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  final String playerUserId;
  final String displayName;
  final int totalXp;
  final int level;
  final List<BadgeModel> badges;
  final DateTime updatedAt;

  PlayerGamification toEntity() => PlayerGamification(
        playerUserId: playerUserId,
        displayName: displayName,
        totalXp: totalXp,
        level: level,
        badges: badges.map((b) => b.toEntity()).toList(),
        updatedAt: updatedAt,
      );
}
