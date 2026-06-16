import 'package:bola_na_rede/features/social/domain/entities/review.dart';

class ReviewModel {
  const ReviewModel({
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

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String,
        gameId: json['gameId'] as String,
        gameType: json['gameType'] as String,
        reviewerUserId: json['reviewerUserId'] as String,
        reviewerDisplayName: json['reviewerDisplayName'] as String,
        revieweeUserId: json['revieweeUserId'] as String,
        revieweeDisplayName: json['revieweeDisplayName'] as String,
        score: json['score'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        comment: json['comment'] as String?,
      );

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

  Review toEntity() => Review(
        id: id,
        gameId: gameId,
        gameType: gameType,
        reviewerUserId: reviewerUserId,
        reviewerDisplayName: reviewerDisplayName,
        revieweeUserId: revieweeUserId,
        revieweeDisplayName: revieweeDisplayName,
        score: score,
        createdAt: createdAt,
        comment: comment,
      );
}

class PlayerScoreModel {
  const PlayerScoreModel({
    required this.playerUserId,
    required this.displayName,
    required this.totalReviews,
    required this.averageScore,
    required this.updatedAt,
  });

  factory PlayerScoreModel.fromJson(Map<String, dynamic> json) =>
      PlayerScoreModel(
        playerUserId: json['playerUserId'] as String,
        displayName: json['displayName'] as String,
        totalReviews: json['totalReviews'] as int,
        averageScore: (json['averageScore'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  final String playerUserId;
  final String displayName;
  final int totalReviews;
  final double averageScore;
  final DateTime updatedAt;

  PlayerScore toEntity() => PlayerScore(
        playerUserId: playerUserId,
        displayName: displayName,
        totalReviews: totalReviews,
        averageScore: averageScore,
        updatedAt: updatedAt,
      );
}
