import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/data/datasources/token_storage.dart';
import 'package:bola_na_rede/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/auth/domain/repositories/auth_repository.dart';

final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, PlayerProfile?>(AuthViewModel.new);

class AuthViewModel extends AsyncNotifier<PlayerProfile?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  @override
  Future<PlayerProfile?> build() async {
    final token = await _tokenStorage.readToken();
    if (token == null) return null;
    try {
      return await _repo.restoreSession(token);
    } on Exception catch (_) {
      await _tokenStorage.clearToken();
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _repo.login(email, password),
    );
    state = result;
    return !result.hasError;
  }

  Future<bool> register(
    String name,
    String email,
    String password, {
    String? position,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _repo.register(name, email, password, position: position),
    );
    state = result;
    return !result.hasError;
  }

  Future<void> logout() async {
    await _repo.logout();
    await _tokenStorage.clearToken();
    state = const AsyncData(null);
  }
}
