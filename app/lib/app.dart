import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_theme.dart';
import 'package:bola_na_rede/features/field/data/datasources/field_mock_datasource.dart';
import 'package:bola_na_rede/features/field/data/repositories/field_repository_impl.dart';
import 'package:bola_na_rede/features/field/presentation/viewmodels/field_viewmodel.dart';
import 'package:bola_na_rede/features/match/data/datasources/match_mock_datasource.dart';
import 'package:bola_na_rede/features/match/data/repositories/match_repository_impl.dart';
import 'package:bola_na_rede/features/match/presentation/viewmodels/match_viewmodel.dart';
import 'package:bola_na_rede/features/profile/data/datasources/profile_mock_datasource.dart';
import 'package:bola_na_rede/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:bola_na_rede/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:bola_na_rede/features/team/data/datasources/team_mock_datasource.dart';
import 'package:bola_na_rede/features/team/data/repositories/team_repository_impl.dart';
import 'package:bola_na_rede/features/team/presentation/viewmodels/team_viewmodel.dart';

class BolaNaRedeApp extends ConsumerWidget {
  const BolaNaRedeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FieldViewModel(
            repository: FieldRepositoryImpl(dataSource: FieldMockDataSource()),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MatchViewModel(
            repository: MatchRepositoryImpl(dataSource: MatchMockDataSource()),
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
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'BolaNaRede',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
