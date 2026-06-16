import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bolanarede_web/core/routes/app_router.dart';
import 'package:bolanarede_web/core/themes/app_theme.dart';

class BolaNaRedeWebApp extends ConsumerWidget {
  const BolaNaRedeWebApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'BolaNaRede — Field Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
