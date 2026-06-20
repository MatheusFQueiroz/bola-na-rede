import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bola_na_rede/app.dart';
import 'package:bola_na_rede/features/auth/data/datasources/auth_datasource_provider.dart';
import 'package:bola_na_rede/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:bola_na_rede/features/auth/data/datasources/token_storage.dart';
import 'package:bola_na_rede/features/home/data/datasources/home_datasource_provider.dart';
import 'package:bola_na_rede/features/home/data/datasources/home_mock_datasource.dart';
import 'package:bola_na_rede/features/match/data/datasources/match_datasource_provider.dart';
import 'package:bola_na_rede/features/match/data/datasources/match_mock_datasource.dart';
import 'package:bola_na_rede/features/peladas/data/datasources/open_game_datasource_provider.dart';
import 'package:bola_na_rede/features/profile/data/datasources/profile_datasource_provider.dart';
import 'package:bola_na_rede/features/profile/data/datasources/profile_mock_datasource.dart';
import 'package:bola_na_rede/features/ranking/data/datasources/ranking_datasource_provider.dart';
import 'package:bola_na_rede/features/ranking/data/datasources/ranking_mock_datasource.dart';
import 'package:bola_na_rede/features/team/data/datasources/team_datasource_provider.dart';
import 'package:bola_na_rede/features/team/data/datasources/team_mock_datasource.dart';
import 'package:bola_na_rede/shared/widgets/app_nav_bar.dart';

import 'helpers/fake_open_game_repository.dart';
import 'helpers/in_memory_token_storage.dart';

Widget _testApp() => ProviderScope(
      overrides: [
        tokenStorageProvider
            .overrideWith((_) => InMemoryTokenStorage()),
        authDataSourceProvider
            .overrideWith((_) => AuthMockDataSource()),
        homeDataSourceProvider
            .overrideWith((_) => HomeMockDataSource()),
        teamDataSourceProvider
            .overrideWith((_) => TeamMockDataSource()),
        rankingDataSourceProvider
            .overrideWith((_) => RankingMockDataSource()),
        matchDataSourceProvider
            .overrideWith((_) => MatchMockDataSource()),
        openGameRepositoryProvider
            .overrideWith((_) => FakeOpenGameRepository()),
        profileDataSourceProvider
            .overrideWith((_) => ProfileMockDataSource()),
      ],
      child: const BolaNaRedeApp(),
    );

Future<void> launchApp(WidgetTester tester) async {
  await tester.pumpWidget(_testApp());
  await tester.pumpAndSettle();
  // Give initial providers (auth restore) time to settle.
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> login(WidgetTester tester) async {
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byType(TextFormField).first,
    'carlos@seed.com',
  );
  await tester.enterText(
    find.byType(TextFormField).last,
    'senha123',
  );
  await tester.pump();

  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
  // Wait for router redirect + home page providers (homeProvider,
  // rankingProvider, etc.) to finish loading mock data.
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Finder navTab(String label) => find.descendant(
      of: find.byType(AppNavBar),
      matching: find.text(label),
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load();
  });

  group('Auth', () {
    testWidgets('splash shows branding and entry buttons', (tester) async {
      await launchApp(tester);

      expect(find.text('BolaNaRede'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.text('Continuar sem conta'), findsOneWidget);
    });

    testWidgets(
      'login with valid credentials navigates to home',
      (tester) async {
        await launchApp(tester);
        await login(tester);

        expect(find.text('Bem-vindo de volta,'), findsOneWidget);
      },
    );

    testWidgets(
      'login shows validation error for short password',
      (tester) async {
        await launchApp(tester);

        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'test@email.com',
        );
        await tester.enterText(find.byType(TextFormField).last, '123');
        await tester.pump();

        await tester.tap(find.text('Entrar'));
        await tester.pump();

        expect(
          find.text('A senha deve ter pelo menos 6 caracteres'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'login shows validation error for invalid email',
      (tester) async {
        await launchApp(tester);

        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'not-an-email',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'senha123',
        );
        await tester.pump();

        await tester.tap(find.text('Entrar'));
        await tester.pump();

        expect(find.text('E-mail inválido'), findsOneWidget);
      },
    );
  });

  group('Home', () {
    testWidgets('home shows quick actions after login', (tester) async {
      await launchApp(tester);
      await login(tester);

      expect(find.text('Buscar partida'), findsOneWidget);
      expect(find.text('Reservar campo'), findsOneWidget);
      expect(find.text('Peladas abertas'), findsOneWidget);
    });

    testWidgets('home shows next match card', (tester) async {
      await launchApp(tester);
      await login(tester);

      expect(find.text('Proxima Partida'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
    });

    testWidgets('home shows ranking dos times section', (tester) async {
      await launchApp(tester);
      await login(tester);

      // rankingProvider is watched inside the home body and loads after
      // homeProvider — give it an extra tick.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Ranking dos times'), findsOneWidget);
    });
  });

  group('Navigation', () {
    testWidgets('ranking tab shows ranking page', (tester) async {
      await launchApp(tester);
      await login(tester);

      await tester.tap(navTab('Ranking'));
      await tester.pumpAndSettle();

      expect(find.text('Times'), findsOneWidget);
      expect(find.text('Jogadores'), findsOneWidget);
    });

    testWidgets('partidas tab shows match list page', (tester) async {
      await launchApp(tester);
      await login(tester);

      await tester.tap(navTab('Partidas'));
      await tester.pumpAndSettle();

      expect(find.text('Partidas'), findsWidgets);
    });

    testWidgets('perfil tab shows profile page', (tester) async {
      await launchApp(tester);
      await login(tester);

      await tester.tap(navTab('Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Carlos Souza'), findsOneWidget);
    });

    testWidgets('tapping inicio tab returns to home', (tester) async {
      await launchApp(tester);
      await login(tester);

      await tester.tap(navTab('Ranking'));
      await tester.pumpAndSettle();

      await tester.tap(navTab('Início'));
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo de volta,'), findsOneWidget);
    });
  });

  group('Ranking', () {
    testWidgets('shows team podium with mock data', (tester) async {
      await launchApp(tester);
      await login(tester);

      await tester.tap(navTab('Ranking'));
      await tester.pumpAndSettle();

      expect(find.text('Uniao Vila'), findsWidgets);
      expect(find.text('Classificacao completa'), findsOneWidget);
    });

    testWidgets('switches to Jogadores tab', (tester) async {
      await launchApp(tester);
      await login(tester);

      await tester.tap(navTab('Ranking'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jogadores'));
      await tester.pumpAndSettle();

      expect(find.text('Carlos Souza'), findsWidgets);
    });

    testWidgets('filter chips change selection', (tester) async {
      await launchApp(tester);
      await login(tester);

      await tester.tap(navTab('Ranking'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Esta semana'));
      await tester.pumpAndSettle();

      expect(find.text('Esta semana'), findsOneWidget);
    });
  });

  group('Peladas', () {
    testWidgets('home quick action opens peladas list', (tester) async {
      await launchApp(tester);
      await login(tester);

      await tester.tap(find.text('Peladas abertas'));
      await tester.pumpAndSettle();

      expect(find.text('Peladas'), findsOneWidget);
      expect(find.text('Pelada da Tarde'), findsOneWidget);
      expect(find.text('Rachao de Sexta'), findsOneWidget);
    });

    testWidgets('peladas list shows sport filter chips', (tester) async {
      await launchApp(tester);
      await login(tester);

      await tester.tap(find.text('Peladas abertas'));
      await tester.pumpAndSettle();

      expect(find.text('Todos'), findsOneWidget);
      // 'Futsal' appears in the filter chip AND in the game card sport label.
      expect(find.text('Futsal'), findsWidgets);
      expect(find.text('Society'), findsWidgets);
      expect(find.text('Campo'), findsOneWidget);
    });

    testWidgets('peladas filter chip tap changes selection', (tester) async {
      await launchApp(tester);
      await login(tester);

      await tester.tap(find.text('Peladas abertas'));
      await tester.pumpAndSettle();

      // 'Futsal' appears in both chip and game card — tap the first (chip).
      await tester.tap(find.text('Futsal').first);
      await tester.pumpAndSettle();

      expect(find.text('Pelada da Tarde'), findsOneWidget);
    });

    testWidgets('back arrow on peladas returns to home', (tester) async {
      await launchApp(tester);
      await login(tester);

      await tester.tap(find.text('Peladas abertas'));
      await tester.pumpAndSettle();

      // First IconButton in the header is the back arrow
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo de volta,'), findsOneWidget);
    });
  });
}
