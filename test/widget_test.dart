import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/main.dart';
import 'package:trading_app/core/widgets/platform_bottom_bar.dart';
import 'package:trading_app/models/user_model.dart';
import 'package:trading_app/repositories/auth/auth_repository.dart';
import 'package:trading_app/repositories/market/market_repository.dart';
import 'package:trading_app/services/market/simulated_exchange_data_source.dart';

void main() {
  late AuthRepository authRepository;
  late SimulatedExchangeDataSource dataSource;
  late MarketRepository marketRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authRepository = AuthRepository(simulationDelay: Duration.zero);
    dataSource = SimulatedExchangeDataSource(
      tickInterval: const Duration(hours: 1),
      randomSeed: 12,
    );
    marketRepository = MarketRepository(dataSource: dataSource);
  });

  tearDown(() {
    marketRepository.dispose();
  });

  testWidgets('TradingApp loads clean LoginScreen when unauthenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      TradingApp(
        authRepository: authRepository,
        marketRepository: marketRepository,
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Login Screen loaded
    expect(find.text('TRADING APP'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);

    // Verify Form Fields
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify Sign In Button
    expect(find.text('Sign In to Terminal'), findsOneWidget);
  });

  testWidgets('TradingApp navigates directly to MainNavigationHub when authenticated without flash', (
    WidgetTester tester,
  ) async {
    final user = UserModel(
      id: 'usr_pro_001',
      email: 'mudasir@gmail.com',
      displayName: 'Mudasir Ali',
      token: 'tok_live_pro_mudasir_8892krwysc',
      accountType: 'pro',
      createdAt: DateTime(2026, 1, 15),
    );

    // Save authenticated user into mock preferences using exact storage key
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_session_user', user.toJson());

    await tester.pumpWidget(
      TradingApp(
        authRepository: authRepository,
        marketRepository: marketRepository,
      ),
    );
    await tester.pumpAndSettle();

    // Verify user landed on MainNavigationHub / Dashboard
    expect(find.text('TRADING TERMINAL'), findsOneWidget);
    expect(find.text('PRO TIER'), findsOneWidget);
    expect(find.byType(PlatformBottomBar), findsOneWidget);

    // Verify LoginScreen is NOT rendered
    expect(find.text('Welcome Back'), findsNothing);
    expect(find.text('Sign In to Terminal'), findsNothing);
  });
}
