import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bola_na_rede/shared/widgets/app_nav_bar.dart';

void main() {
  group('AppNavBar', () {
    testWidgets('renders 5 labelled items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppNavBar(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Buscar'), findsOneWidget);
      expect(find.text('Partidas'), findsOneWidget);
      expect(find.text('Ranking'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('calls onTap with correct index', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppNavBar(
              currentIndex: 0,
              onTap: (i) => tapped = i,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buscar'));
      expect(tapped, 1);
    });
  });
}
