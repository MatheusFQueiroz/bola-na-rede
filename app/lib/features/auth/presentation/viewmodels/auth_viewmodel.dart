import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthViewState { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repository;

  AuthViewModel({required this.repository});

  AuthViewState _state = AuthViewState.idle;
  PlayerProfile? _currentUser;
  String? _error;

  AuthViewState get state => _state;
  PlayerProfile? get currentUser => _currentUser;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // time do usuário logado — fixo por enquanto, virá da API
  String get currentTeamId => 'team-001';
  String get currentTeamName => _currentUser?.displayName ?? 'Meu Time';

  Future<bool> login(String email, String password) async {
    _state = AuthViewState.loading;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await repository.login(email, password);
      _state = AuthViewState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _state = AuthViewState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _state = AuthViewState.loading;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await repository.register(name, email, password);
      _state = AuthViewState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _state = AuthViewState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await repository.logout();
    _currentUser = null;
    _state = AuthViewState.idle;
    notifyListeners();
  }
}
