import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/social/data/models/review_model.dart';
import 'package:bola_na_rede/features/social/domain/entities/review.dart';
import 'package:bola_na_rede/features/social/domain/repositories/review_repository.dart';

class ReviewHttpDatasource implements ReviewRepository {
  const ReviewHttpDatasource({required this.dio});

  final Dio dio;

  @override
  Future<Review> submitReview({
    required String gameId,
    required String gameType,
    required String revieweeUserId,
    required int score,
    String? comment,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/v1/reviews',
      data: <String, dynamic>{
        'gameId': gameId,
        'gameType': gameType,
        'revieweeUserId': revieweeUserId,
        'score': score,
        if (comment != null) 'comment': comment,
      },
    );
    return ReviewModel.fromJson(response.data!).toEntity();
  }

  @override
  Future<PlayerScore> getPlayerScore(String userId) async {
    final response = await dio
        .get<Map<String, dynamic>>('/v1/scores/players/$userId');
    return PlayerScoreModel.fromJson(response.data!).toEntity();
  }
}
