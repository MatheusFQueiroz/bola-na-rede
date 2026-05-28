import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:bola_na_rede/shared/widgets/app_nav_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabRoutes = [
    '/home',
    '/search',
    '/match',
    '/ranking',
    '/profile',
  ];

  int _locationToIndex(String location) {
    final idx = _tabRoutes.indexWhere(location.startsWith);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: AppNavBar(
        currentIndex: _locationToIndex(location),
        onTap: (i) => context.go(_tabRoutes[i]),
      ),
    );
  }
}
