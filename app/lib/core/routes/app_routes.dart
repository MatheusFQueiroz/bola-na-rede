// lib/core/routes/app_routes.dart

import 'package:flutter/material.dart';
import '../../features/auth/presentation/views/splash_page.dart';
import '../../features/auth/presentation/views/login_page.dart';
import '../../features/auth/presentation/views/register_page.dart';
import '../../features/home/presentation/views/home_page.dart';
import '../../features/field/presentation/views/field_catalog_page.dart';
import '../../features/field/presentation/views/field_detail_page.dart';
import '../../features/search/presentation/views/search_page.dart';
import '../../features/match/presentation/views/match_list_page.dart';
import '../../features/match/presentation/views/match_detail_page.dart';
import '../../features/match/presentation/views/create_match_page.dart';
import '../../features/match/presentation/views/register_result_page.dart';
import '../../features/team/presentation/views/team_manage_page.dart';
import '../../features/team/presentation/views/create_team_page.dart';
import '../../features/ranking/presentation/views/ranking_page.dart';
import '../../features/profile/presentation/views/profile_page.dart';
import '../../features/team/presentation/views/team_search_page.dart';

abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String fieldCatalog = '/fields';
  static const String fieldDetail = '/fields/detail';
  static const String search = '/search';
  static const String matchList = '/match';
  static const String matchDetail = '/match/detail';
  static const String createMatch = '/match/create';
  static const String registerResult = '/match/result';
  static const String teamManage = '/team/manage';
  static const String createTeam = '/team/create';
  static const String ranking = '/ranking';
  static const String profile = '/profile';
  static const String teamSearch = '/team/search';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashPage(),
        login: (_) => const LoginPage(),
        register: (_) => const RegisterPage(),
        home: (_) => const HomePage(),
        fieldCatalog: (_) => const FieldCatalogPage(),
        fieldDetail: (_) => const FieldDetailPage(),
        search: (_) => const SearchPage(),
        matchList: (_) => const MatchListPage(),
        matchDetail: (_) => const MatchDetailPage(),
        createMatch: (_) => const CreateMatchPage(),
        registerResult: (_) => const RegisterResultPage(),
        teamManage: (_) => const TeamManagePage(),
        createTeam: (_) => const CreateTeamPage(),
        ranking: (_) => const RankingPage(),
        profile: (_) => const ProfilePage(),
        teamSearch: (_) => const TeamSearchPage(),
      };
}
