import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/profile/data/repositories/profile_repository_provider.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/profile_repository.dart';
import 'package:bola_na_rede/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../../helpers/fake_repositories.dart';

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<PlayerProfile> getProfile(String userId) async =>
      fakeProfile(name: 'User');
  @override
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId) async =>
      [];
}

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
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

    test('loadProfile sets status to success', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(profileViewModelProvider.notifier).loadProfile();

      expect(
          c.read(profileViewModelProvider).status, ProfileStatus.success);
      expect(c.read(profileViewModelProvider).profile, isNotNull);
    });
  });
}
