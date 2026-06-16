class Badge {
  const Badge({required this.code, required this.earnedAt});

  final String code;
  final DateTime earnedAt;
}

class PlayerGamification {
  const PlayerGamification({
    required this.playerUserId,
    required this.displayName,
    required this.totalXp,
    required this.level,
    required this.badges,
    required this.updatedAt,
  });

  final String playerUserId;
  final String displayName;
  final int totalXp;
  final int level;
  final List<Badge> badges;
  final DateTime updatedAt;
}
