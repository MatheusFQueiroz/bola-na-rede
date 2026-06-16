import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/social/data/datasources/review_datasource_provider.dart';
import 'package:bola_na_rede/features/social/domain/entities/review.dart';

class ReviewViewModel extends AsyncNotifier<Review?> {
  @override
  Future<Review?> build() async => null;

  Future<void> submit({
    required String gameId,
    required String gameType,
    required String revieweeUserId,
    required int score,
    String? comment,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reviewRepositoryProvider).submitReview(
            gameId: gameId,
            gameType: gameType,
            revieweeUserId: revieweeUserId,
            score: score,
            comment: comment,
          ),
    );
  }
}

final reviewViewModelProvider =
    AsyncNotifierProvider<ReviewViewModel, Review?>(ReviewViewModel.new);
