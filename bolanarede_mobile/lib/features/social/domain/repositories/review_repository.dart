import 'package:bola_na_rede/features/social/domain/entities/review.dart';

abstract class ReviewRepository {
  Future<Review> submitReview({
    required String gameId,
    required String gameType,
    required String revieweeUserId,
    required int score,
    String? comment,
  });

  Future<PlayerScore> getPlayerScore(String userId);
}
