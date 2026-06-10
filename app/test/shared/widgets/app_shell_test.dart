import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:bola_na_rede/shared/widgets/app_nav_bar.dart';
import 'package:bola_na_rede/shared/widgets/app_shell.dart';

void main() {
  group('AppShell', () {
    GoRouter buildRouter({String initial = '/home'}) => GoRouter(
          initialLocation: initial,
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) =>
                  AppShell(navigationShell: navigationShell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/home',
                      builder: (_, __) => const Text('home body'),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/search',
                      builder: (_, __) => const Text('search body'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

    testWidgets('renders child and AppNavBar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: buildRouter()),
        ),
      );
      await tester.pump();
      expect(find.text('home body'), findsOneWidget);
      expect(find.byType(AppNavBar), findsOneWidget);
    });

    testWidgets('highlights tab matching current location', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: buildRouter(initial: '/search'),
          ),
        ),
      );
      await tester.pump();
      final navBar = tester.widget<AppNavBar>(find.byType(AppNavBar));
      expect(navBar.currentIndex, 1);
    });
  });
}
