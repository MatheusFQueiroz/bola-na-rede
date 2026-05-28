import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_theme.dart';
import 'package:bola_na_rede/features/profile/data/datasources/profile_mock_datasource.dart';
import 'package:bola_na_rede/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:bola_na_rede/features/profile/presentation/viewmodels/profile_viewmodel.dart';
class BolaNaRedeApp extends ConsumerWidget {
  const BolaNaRedeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MultiProvider(
      providers: [
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
