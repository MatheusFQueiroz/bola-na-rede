class Review {
  const Review({
    required this.id,
    required this.gameId,
    required this.gameType,
    required this.reviewerUserId,
    required this.reviewerDisplayName,
    required this.revieweeUserId,
    required this.revieweeDisplayName,
    required this.score,
    required this.createdAt,
    this.comment,
  });

  final String id;
  final String gameId;
  final String gameType;
  final String reviewerUserId;
  final String reviewerDisplayName;
  final String revieweeUserId;
  final String revieweeDisplayName;
  final int score;
  final DateTime createdAt;
  final String? comment;
}

class PlayerScore {
  const PlayerScore({
    required this.playerUserId,
    required this.displayName,
    required this.totalReviews,
    required this.averageScore,
    required this.updatedAt,
  });

  final String playerUserId;
  final String displayName;
  final int totalReviews;
  final double averageScore;
  final DateTime updatedAt;
}
