import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/auth/presentation/views/login_page.dart';
import 'package:bola_na_rede/features/auth/presentation/views/register_page.dart';
import 'package:bola_na_rede/features/auth/presentation/views/splash_page.dart';
import 'package:bola_na_rede/features/field/presentation/views/field_catalog_page.dart';
import 'package:bola_na_rede/features/field/presentation/views/field_detail_page.dart';
import 'package:bola_na_rede/features/home/presentation/views/home_page.dart';
import 'package:bola_na_rede/features/match/presentation/views/create_match_page.dart';
import 'package:bola_na_rede/features/match/presentation/views/match_detail_page.dart';
import 'package:bola_na_rede/features/match/presentation/views/match_list_page.dart';
import 'package:bola_na_rede/features/match/presentation/views/register_result_page.dart';
import 'package:bola_na_rede/features/notificacoes/presentation/views/notifications_page.dart';
import 'package:bola_na_rede/features/peladas/presentation/views/create_pelada_page.dart';
import 'package:bola_na_rede/features/peladas/presentation/views/pelada_detail_page.dart';
import 'package:bola_na_rede/features/peladas/presentation/views/peladas_list_page.dart';
import 'package:bola_na_rede/features/profile/presentation/views/edit_profile_page.dart';
import 'package:bola_na_rede/features/profile/presentation/views/profile_page.dart';
import 'package:bola_na_rede/features/ranking/presentation/views/ranking_page.dart';
import 'package:bola_na_rede/features/search/presentation/views/search_page.dart';
import 'package:bola_na_rede/features/team/presentation/views/create_team_page.dart';
import 'package:bola_na_rede/features/team/presentation/views/team_manage_page.dart';
import 'package:bola_na_rede/features/team/presentation/views/team_search_page.dart'
    show TeamSearchMode, TeamSearchPage;
import 'package:bola_na_rede/shared/widgets/app_shell.dart';

/// Permissivo por ora: navegação livre mesmo sem sessão. Vira `true` quando
/// a autenticação entrar no roadmap — o `redirect` abaixo já está completo.
const kAuthGateEnabled = true;

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authViewModelProvider, (_, __) => notifyListeners());
  }
}

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const search = '/search';
  static const matchList = '/match';
  static const matchDetail = '/match/detail/:id';
  static const createMatch = '/match/create';
  static const registerResult = '/match/result/:id';
  static String registerResultOf(String id) => '/match/result/$id';
  static const ranking = '/ranking';
  static const profile = '/profile';
  static const fieldCatalog = '/fields';
  static const fieldDetail = '/fields/detail/:id';
  static const teamManage = '/team/manage/:id';
  static const createTeam = '/team/create';
  static const teamSearch = '/team/search';
  static const teamSearchJoin = '/team/search/join';
  static const peladas = '/peladas';
  static const peladaDetail = '/peladas/:id';
  static const createPelada = '/peladas/create';
  static const notifications = '/notifications';
  static const editProfile = '/profile/edit';

  static String matchDetailOf(String id) => '/match/detail/$id';
  static String fieldDetailOf(String id) => '/fields/detail/$id';
  static String teamManageOf(String id) => '/team/manage/$id';
  static String peladaDetailOf(String id) => '/peladas/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefreshNotifier(ref);
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      if (!kAuthGateEnabled) return null;

      final isLoggedIn = ref.read(authViewModelProvider).value != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.splash;

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.splash;
      if (isLoggedIn &&
          (location == AppRoutes.login || location == AppRoutes.register)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (_, __) => const SearchPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.matchList,
                builder: (_, __) => const MatchListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.ranking,
                builder: (_, __) => const RankingPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.fieldCatalog,
        builder: (_, __) => const FieldCatalogPage(),
      ),
      GoRoute(
        path: AppRoutes.fieldDetail,
        builder: (_, __) => const FieldDetailPage(),
      ),
      GoRoute(
        path: AppRoutes.matchDetail,
        builder: (_, __) => const MatchDetailPage(),
      ),
      GoRoute(
        path: AppRoutes.createMatch,
        builder: (_, __) => const CreateMatchPage(),
      ),
      GoRoute(
        path: AppRoutes.registerResult,
        builder: (_, state) => RegisterResultPage(
          gameId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.teamManage,
        builder: (_, __) => const TeamManagePage(),
      ),
      GoRoute(
        path: AppRoutes.createTeam,
        builder: (_, __) => const CreateTeamPage(),
      ),
      GoRoute(
        path: AppRoutes.teamSearch,
        builder: (_, __) => const TeamSearchPage(),
      ),
      GoRoute(
        path: AppRoutes.teamSearchJoin,
        builder: (_, __) =>
            const TeamSearchPage(mode: TeamSearchMode.joinTeam),
      ),
      GoRoute(
        path: AppRoutes.peladas,
        builder: (_, __) => const PeladasListPage(),
      ),
      GoRoute(
        path: AppRoutes.createPelada,
        builder: (_, __) => const CreatePeladaPage(),
      ),
      GoRoute(
        path: AppRoutes.peladaDetail,
        builder: (context, state) => PeladaDetailPage(
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, __) => const EditProfilePage(),
      ),
    ],
  );
});
