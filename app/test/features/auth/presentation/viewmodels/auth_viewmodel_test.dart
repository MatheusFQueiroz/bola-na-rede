import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/auth/data/datasources/token_storage.dart';
import 'package:bola_na_rede/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../helpers/fake_repositories.dart';

class FakeTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clearToken() async => _token = null;
}

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        ],
      );

  group('AuthViewModel', () {
    test('initial state resolves to no user when there is no token', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await expectLater(
        c.read(authViewModelProvider.future),
        completion(isNull),
      );
    });

    test('login sets state to data with the logged user', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      final result =
          await c.read(authViewModelProvider.notifier).login('a@b.com', '123456');

      expect(result, isTrue);
      expect(c.read(authViewModelProvider).value, isNotNull);
    });

    test('login with short password sets state to error', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      final result =
          await c.read(authViewModelProvider.notifier).login('a@b.com', 'ab');

      expect(result, isFalse);
      expect(c.read(authViewModelProvider).hasError, isTrue);
    });

    test('logout clears the user and resets state to data(null)', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(authViewModelProvider.notifier).login('a@b.com', '123456');
      await c.read(authViewModelProvider.notifier).logout();

      expect(c.read(authViewModelProvider).value, isNull);
    });
  });
}
