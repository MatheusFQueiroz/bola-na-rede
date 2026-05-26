import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../domain/repositories/profile_repository.dart';

enum ProfileViewState { idle, loading, success, error }

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository repository;
  final AuthViewModel authViewModel;

  ProfileViewModel({
    required this.repository,
    required this.authViewModel,
  });

  ProfileViewState _state = ProfileViewState.idle;
  PlayerProfile? _profile;
  List<Map<String, dynamic>> _recentMatches = [];
  String? _error;

  ProfileViewState get state => _state;
  PlayerProfile? get profile => _profile;
  List<Map<String, dynamic>> get recentMatches => _recentMatches;
  String? get error => _error;

  // stats fixos por enquanto — virão da API
  int get totalMatches => 42;
  int get totalGoals => 28;
  int get totalWins => 28;
  String get winRate => '67%';

  Future<void> loadProfile() async {
    // se já tem usuário logado usa os dados dele
    if (authViewModel.currentUser != null) {
      _profile = authViewModel.currentUser;
    }

    _state = ProfileViewState.loading;
    _error = null;
    notifyListeners();

    try {
      final userId = authViewModel.currentUser?.userId ?? 'user-001';
      final results = await Future.wait([
        repository.getProfile(userId),
        repository.getRecentMatches(userId),
      ]);
      _profile = results[0] as PlayerProfile;
      _recentMatches = results[1] as List<Map<String, dynamic>>;
      _state = ProfileViewState.success;
    } catch (e) {
      _error = 'Não foi possível carregar o perfil.';
      _state = ProfileViewState.error;
    }
    notifyListeners();
  }
}
