import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/blocs/auth/auth_bloc.dart';
import 'package:trading_app/blocs/auth/auth_state.dart';
import 'package:trading_app/blocs/market/market_bloc.dart';
import 'package:trading_app/blocs/market/market_state.dart';
import 'package:trading_app/blocs/theme/theme_cubit.dart';
import 'package:trading_app/models/user_model.dart';
import 'package:trading_app/repositories/auth/auth_repository.dart';
import 'package:trading_app/repositories/market/market_repository.dart';
import 'package:trading_app/services/market/simulated_exchange_data_source.dart';
import 'package:trading_app/views/dashboard/dashboard_screen.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    late AuthRepository authRepository;
    late AuthBloc authBloc;
    late SimulatedExchangeDataSource dataSource;
    late MarketRepository marketRepository;
    late MarketBloc marketBloc;
    late ThemeCubit themeCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authRepository = AuthRepository();
      authBloc = AuthBloc(authRepository: authRepository);

      // Pre-authenticate with Mudasir Ali
      authBloc.emit(
        Authenticated(
          user: UserModel(
            id: 'usr_001',
            email: 'mudasir@gmail.com',
            displayName: 'Mudasir Ali',
            token: 'mock_jwt_token',
            accountType: 'pro',
            createdAt: DateTime.now(),
          ),
        ),
      );

      dataSource = SimulatedExchangeDataSource(
        tickInterval: const Duration(hours: 1),
        randomSeed: 42,
      );
      marketRepository = MarketRepository(dataSource: dataSource);
      marketBloc = MarketBloc(marketRepository: marketRepository);
      themeCubit = ThemeCubit();
    });

    tearDown(() {
      authBloc.close();
      marketBloc.close();
      themeCubit.close();
      marketRepository.dispose();
    });

    Widget createTestApp({VoidCallback? onNavigateToSearch}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<MarketBloc>.value(value: marketBloc),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(
          home: DashboardScreen(
            onNavigateToSearch: onNavigateToSearch,
          ),
        ),
      );
    }

    testWidgets('Renders Terminal AppBar and User Tier Badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('TRADING TERMINAL'), findsOneWidget);
      expect(find.text('PRO TIER'), findsOneWidget);
    });

    testWidgets('Renders Portfolio Card with \$100,000.00 and Quick Action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.text('VIRTUAL PORTFOLIO VALUE'), findsOneWidget);
      expect(find.text('\$100,000.00'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Funds'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
    });

    testWidgets('Tapping Explore triggers onNavigateToSearch callback', (
      WidgetTester tester,
    ) async {
      bool searchNavigated = false;
      await tester.pumpWidget(
        createTestApp(
          onNavigateToSearch: () => searchNavigated = true,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Explore'));
      await tester.pump();

      expect(searchNavigated, isTrue);
    });

    testWidgets('Tapping Funds button shows Virtual Capital Active dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      await tester.tap(find.text('Funds'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Virtual Capital Active'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      await tester.tap(find.text('Understood'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Virtual Capital Active'), findsNothing);
    });

    testWidgets('Market movers tabs switch between Gainers, Losers, and Active', (
      WidgetTester tester,
    ) async {
      final instruments = await marketRepository.getInstruments();
      marketBloc.emit(
        MarketLoaded(
          instruments: instruments,
          searchResults: instruments,
          selectedSymbol: 'AAPL',
          selectedCandles: const [],
          isFeedLive: true,
          feedVenue: 'Simulated Exchange Feed • Real-Time',
          lastTickTimestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // Check Movers section header
      expect(find.text('Market Movers'), findsOneWidget);
      expect(find.text('Gainers'), findsOneWidget);
      expect(find.text('Losers'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Switch to Losers
      await tester.tap(find.text('Losers'));
      await tester.pump();

      // Switch to Active
      await tester.tap(find.text('Active'));
      await tester.pump();
    });
  });
}
