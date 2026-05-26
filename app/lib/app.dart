import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/data/datasources/auth_mock_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/field/data/datasources/field_mock_datasource.dart';
import 'features/field/data/repositories/field_repository_impl.dart';
import 'features/field/presentation/viewmodels/field_viewmodel.dart';
import 'features/match/data/datasources/match_mock_datasource.dart';
import 'features/match/data/repositories/match_repository_impl.dart';
import 'features/match/presentation/viewmodels/match_viewmodel.dart';
import 'features/team/data/datasources/team_mock_datasource.dart';
import 'features/team/data/repositories/team_repository_impl.dart';
import 'features/team/presentation/viewmodels/team_viewmodel.dart';
import 'features/ranking/data/datasources/ranking_mock_datasource.dart';
import 'features/ranking/data/repositories/ranking_repository_impl.dart';
import 'features/ranking/presentation/viewmodels/ranking_viewmodel.dart';
import 'features/profile/data/datasources/profile_mock_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'features/home/data/datasources/home_mock_datasource.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/presentation/viewmodels/home_viewmodel.dart';
import 'features/search/data/datasources/search_mock_datasource.dart';
import 'features/search/data/repositories/search_repository_impl.dart';
import 'features/search/presentation/viewmodels/search_viewmodel.dart';

class BolaNaRedeApp extends StatelessWidget {
  const BolaNaRedeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = AuthViewModel(
      repository: AuthRepositoryImpl(dataSource: AuthMockDataSource()),
    );

    final rankingViewModel = RankingViewModel(
      repository: RankingRepositoryImpl(dataSource: RankingMockDataSource()),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProvider.value(value: rankingViewModel),
        ChangeNotifierProvider(
          create: (_) => FieldViewModel(
            repository: FieldRepositoryImpl(dataSource: FieldMockDataSource()),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MatchViewModel(
            repository: MatchRepositoryImpl(dataSource: MatchMockDataSource()),
            authViewModel: authViewModel,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TeamViewModel(
            repository: TeamRepositoryImpl(dataSource: TeamMockDataSource()),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(
            repository: ProfileRepositoryImpl(
              dataSource: ProfileMockDataSource(),
            ),
            authViewModel: authViewModel,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
            repository: HomeRepositoryImpl(dataSource: HomeMockDataSource()),
            authViewModel: authViewModel,
            rankingViewModel: rankingViewModel,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchViewModel(
            repository: SearchRepositoryImpl(
              dataSource: SearchMockDataSource(),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'BolaNaRede',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
