import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../helpers/fake_repositories.dart';

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );

  group('AuthViewModel', () {
    test('initial state is idle with no user', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      final state = c.read(authViewModelProvider);
      expect(state.status, AuthStatus.idle);
      expect(state.currentUser, isNull);
    });

    test('login sets status to success and stores user', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final result =
          await c.read(authViewModelProvider.notifier).login('a@b.com', '123456');
      expect(result, isTrue);
      expect(c.read(authViewModelProvider).status, AuthStatus.success);
      expect(c.read(authViewModelProvider).currentUser, isNotNull);
    });

    test('login with short password sets status to error', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final result =
          await c.read(authViewModelProvider.notifier).login('a@b.com', 'ab');
      expect(result, isFalse);
      expect(c.read(authViewModelProvider).status, AuthStatus.error);
    });

    test('logout clears user and resets to idle', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(authViewModelProvider.notifier).login('a@b.com', '123456');
      await c.read(authViewModelProvider.notifier).logout();
      expect(c.read(authViewModelProvider).status, AuthStatus.idle);
      expect(c.read(authViewModelProvider).currentUser, isNull);
    });
  });
}
