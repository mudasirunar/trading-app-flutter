import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/main.dart';
import 'package:trading_app/repositories/auth/auth_repository.dart';

void main() {
  late AuthRepository authRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authRepository = AuthRepository();
  });

  testWidgets('TradingApp loads clean LoginScreen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(TradingApp(authRepository: authRepository));
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
}
