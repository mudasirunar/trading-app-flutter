import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/blocs/alerts/alerts_bloc.dart';
import 'package:trading_app/blocs/alerts/alerts_state.dart';
import 'package:trading_app/blocs/auth/auth_bloc.dart';
import 'package:trading_app/blocs/auth/auth_state.dart';
import 'package:trading_app/blocs/market/market_bloc.dart';
import 'package:trading_app/blocs/theme/theme_cubit.dart';
import 'package:trading_app/blocs/trading/trading_bloc.dart';
import 'package:trading_app/blocs/trading/trading_state.dart';
import 'package:trading_app/core/widgets/app_dialog.dart';
import 'package:trading_app/core/widgets/platform_segmented_tabs_control.dart';
import 'package:trading_app/models/alert_model.dart';
import 'package:trading_app/models/user_model.dart';
import 'package:trading_app/repositories/alerts/alerts_repository.dart';
import 'package:trading_app/repositories/auth/auth_repository.dart';
import 'package:trading_app/repositories/market/market_repository.dart';
import 'package:trading_app/repositories/trading/trading_repository.dart';
import 'package:trading_app/services/market/simulated_exchange_data_source.dart';
import 'package:trading_app/services/storage/local_storage_service.dart';
import 'package:trading_app/views/alerts/alerts_screen.dart';
import 'package:trading_app/views/settings/settings_screen.dart';

void main() {
  group('ThemeCubit 3-Theme System Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Defaults to ThemeMode.system on fresh launch', () {
      final cubit = ThemeCubit();
      expect(cubit.state, equals(ThemeMode.system));
    });

    test('Toggle theme switches between dark and light', () async {
      final cubit = ThemeCubit();
      expect(cubit.state, equals(ThemeMode.system));

      await cubit.toggleTheme();
      expect(cubit.state, equals(ThemeMode.dark));

      await cubit.toggleTheme();
      expect(cubit.state, equals(ThemeMode.light));
    });

    test('Directly sets ThemeMode and persists to SharedPreferences', () async {
      final cubit = ThemeCubit();

      await cubit.setTheme(ThemeMode.dark);
      expect(cubit.state, equals(ThemeMode.dark));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_theme_mode_v2'), equals('dark'));

      await cubit.setTheme(ThemeMode.light);
      expect(cubit.state, equals(ThemeMode.light));
      expect(prefs.getString('user_theme_mode_v2'), equals('light'));

      await cubit.setTheme(ThemeMode.system);
      expect(cubit.state, equals(ThemeMode.system));
      expect(prefs.getString('user_theme_mode_v2'), equals('system'));
    });

    test('Loads existing string preference on initialization', () async {
      SharedPreferences.setMockInitialValues({'user_theme_mode_v2': 'dark'});
      final cubit = ThemeCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, equals(ThemeMode.dark));
    });

    test('Backward compatibility: loads legacy bool preference if string missing', () async {
      SharedPreferences.setMockInitialValues({'user_theme_mode': true});
      final cubit = ThemeCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, equals(ThemeMode.light));
    });
  });

  group('SettingsScreen Widget Tests', () {
    late AuthRepository authRepository;
    late AuthBloc authBloc;
    late SimulatedExchangeDataSource dataSource;
    late MarketRepository marketRepository;
    late MarketBloc marketBloc;
    late ThemeCubit themeCubit;
    late LocalStorageService storageService;
    late TradingRepository tradingRepository;
    late TradingBloc tradingBloc;
    late AlertsRepository alertsRepository;
    late AlertsBloc alertsBloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      authRepository = AuthRepository();
      authBloc = AuthBloc(authRepository: authRepository);

      authBloc.emit(
        Authenticated(
          user: UserModel(
            id: 'usr_pro_01',
            email: 'trader@institutional.apex',
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
      storageService = LocalStorageService();
      await storageService.init();
      tradingRepository = TradingRepository(storage: storageService);
      tradingBloc = TradingBloc(repository: tradingRepository);
      alertsRepository = AlertsRepository(storage: storageService);
      alertsBloc = AlertsBloc(repository: alertsRepository);
    });

    Widget createWidgetUnderTest() {
      return MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<MarketBloc>.value(value: marketBloc),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider<TradingBloc>.value(value: tradingBloc),
          BlocProvider<AlertsBloc>.value(value: alertsBloc),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              themeMode: themeMode,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              home: const SettingsScreen(),
            );
          },
        ),
      );
    }

    testWidgets('Renders all institutional settings sections and profile card',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Title & Profile
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Mudasir Ali'), findsOneWidget);
      expect(find.text('trader@institutional.apex'), findsOneWidget);
      expect(find.text('PRO TIER'), findsOneWidget);

      // Section Headings
      expect(find.text('INTERFACE THEME'), findsOneWidget);
      expect(find.text('PRICE ALERTS & TRIGGERS'), findsOneWidget);
      expect(find.text('TRADING PREFERENCES'), findsOneWidget);
      expect(find.text('CAPITAL & RISK MANAGEMENT'), findsOneWidget);
      expect(find.text('SECURITY & SYSTEM'), findsOneWidget);
      expect(find.text('TERMINAL INFORMATION'), findsOneWidget);

      // Theme Tabs
      expect(find.byType(PlatformSegmentedTabsControl), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);

      // Alerts Card
      expect(find.text('Price Alerts Hub'), findsOneWidget);

      // Trading preferences
      expect(find.text('Default Execution Type'), findsOneWidget);
      expect(find.text('Slippage Tolerance (BPS)'), findsOneWidget);
      expect(find.text('Require Order Confirmation'), findsOneWidget);

      // Virtual Account reset
      expect(find.text('Reset Virtual Account to \$100,000'), findsOneWidget);

      // Sign out
      expect(find.text('Sign Out of Terminal'), findsOneWidget);
    });

    testWidgets('Theme Segmented Control switches theme on tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(themeCubit.state, equals(ThemeMode.system));

      // Tap 'Dark' tab
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(themeCubit.state, equals(ThemeMode.dark));

      // Tap 'Light' tab
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(themeCubit.state, equals(ThemeMode.light));

      // Tap 'System' tab
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      expect(themeCubit.state, equals(ThemeMode.system));
    });

    testWidgets('Displays active alert count badge and navigates to AlertsScreen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Emit 2 active alerts
      alertsBloc.emit(
        AlertsLoaded(
          alerts: [
            AlertModel(
              id: 'a1',
              symbol: 'AAPL',
              targetPrice: 200.0,
              condition: AlertCondition.risesAbove,
              status: AlertStatus.active,
              createdAt: DateTime.now(),
            ),
            AlertModel(
              id: 'a2',
              symbol: 'TSLA',
              targetPrice: 180.0,
              condition: AlertCondition.dropsBelow,
              status: AlertStatus.active,
              createdAt: DateTime.now(),
            ),
          ],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('2 ACTIVE'), findsOneWidget);
      expect(
        find.textContaining('Monitoring 2 active price triggers'),
        findsOneWidget,
      );

      // Tap Alerts Hub Card
      await tester.tap(find.text('Price Alerts Hub'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertsScreen), findsOneWidget);
    });

    testWidgets('Reset Virtual Account button opens confirmation modal and dispatches reset',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Reset button
      final resetButton = find.text('Reset Virtual Account to \$100,000');
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Confirmation dialog should be displayed
      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text('Reset Virtual Portfolio?'), findsOneWidget);
      expect(find.text('Reset to \$100k'), findsOneWidget);

      // Tap confirmation
      await tester.tap(find.text('Reset to \$100k'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Modal dismissed and success SnackBar shown
      expect(find.byType(AppDialog), findsNothing);
      expect(
        find.text('Portfolio successfully reinitialized to \$100,000.00 cash.'),
        findsOneWidget,
      );

      // Verify trading state is initialized with $100,000
      expect(tradingBloc.state, isA<TradingLoaded>());
      final loaded = tradingBloc.state as TradingLoaded;
      expect(loaded.virtualCash, equals(100000.0));
      expect(loaded.holdings, isEmpty);

      // Dismiss the SnackBar cleanly so its countdown animation doesn't hang pumpAndSettle
      if (find.byIcon(Icons.close_rounded).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.close_rounded).first);
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Tapping Sign Out button prompts confirmation modal',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final signOutBtn = find.text('Sign Out of Terminal');
      await tester.ensureVisible(signOutBtn);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text('Confirm Sign Out'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AppDialog), findsNothing);
    });
  });
}
