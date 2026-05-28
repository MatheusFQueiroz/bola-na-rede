import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/profile/data/repositories/profile_repository_provider.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/profile_repository.dart';
import 'package:bola_na_rede/features/profile/presentation/viewmodels/profile_viewmodel.dart';

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<PlayerProfile> getProfile(String userId) async =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId) async =>
      throw UnimplementedError();
}

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          profileRepositoryProvider
              .overrideWithValue(FakeProfileRepository()),
        ],
      );

  group('ProfileViewModel', () {
    test('initial state is idle with null profile', () {
      final c = makeContainer();
      addTearDown(c.dispose);

      expect(c.read(profileViewModelProvider).status, ProfileStatus.idle);
      expect(c.read(profileViewModelProvider).profile, isNull);
    });

    test('loadProfile sets status to error when repository throws', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(profileViewModelProvider.notifier).loadProfile();

      expect(c.read(profileViewModelProvider).status, ProfileStatus.error);
    });
  });
}
