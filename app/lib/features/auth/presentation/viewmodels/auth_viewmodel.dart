import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/auth/domain/repositories/auth_repository.dart';

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final PlayerProfile? currentUser;
  final String? error;

  const AuthState({required this.status, this.currentUser, this.error});

  const AuthState.initial()
      : status = AuthStatus.idle,
        currentUser = null,
        error = null;

  bool get isLoggedIn => currentUser != null;
  String get currentTeamId => 'team-001';
  String get currentTeamName => currentUser?.displayName ?? 'Meu Time';

  AuthState copyWith({
    AuthStatus? status,
    PlayerProfile? currentUser,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        currentUser: currentUser ?? this.currentUser,
        error: error ?? this.error,
      );
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.initial();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await _repo.login(email, password);
      state = state.copyWith(status: AuthStatus.success, currentUser: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await _repo.register(name, email, password);
      state = state.copyWith(status: AuthStatus.success, currentUser: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.initial();
  }
}
