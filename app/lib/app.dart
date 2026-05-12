import 'package:flutter/material.dart';
import 'core/themes/app_theme.dart';
import 'core/routes/app_routes.dart';

class BolaNaRedeApp extends StatelessWidget {
  const BolaNaRedeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BolaNaRede',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
