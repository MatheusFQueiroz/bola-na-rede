import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/profile/data/repositories/profile_repository_provider.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/profile_repository.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/update_profile_input.dart';
import 'package:bola_na_rede/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import '../../../../helpers/fake_repositories.dart';

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<PlayerProfile> getProfile(String userId) async =>
      fakeProfile(name: 'User');
  @override
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId) async =>
      [];
  @override
  Future<PlayerProfile> updateProfile(UpdateProfileInput input) async =>
      fakeProfile(name: input.displayName);
}

ProviderContainer makeContainer() => ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
      ],
    );

void main() {
  group('profileProvider', () {
    test('starts loading', () {
      final c = makeContainer();
      addTearDown(c.dispose);

      expect(c.read(profileProvider), isA<AsyncLoading<ProfileData>>());
    });

    test('resolves to ProfileData with non-null profile', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      final data = await c.read(profileProvider.future);
      expect(data.profile, isNotNull);
      expect(data.recentMatches, isEmpty);
    });
  });
}
