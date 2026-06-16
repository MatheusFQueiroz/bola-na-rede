import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:bola_na_rede/shared/widgets/app_nav_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          // Re-tapping the active tab pops it back to the branch root.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
