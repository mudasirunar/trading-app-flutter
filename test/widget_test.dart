import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TradingApp design showcase loads and renders core components', (WidgetTester tester) async {
    await tester.pumpWidget(const TradingApp());
    await tester.pumpAndSettle();

    // Verify Title & Design Showcase loaded
    expect(find.text('Trading App Design System'), findsOneWidget);
    expect(find.text('Phase 2: Design Tokens & Reusable UI'), findsOneWidget);

    // Verify Form Fields
    expect(find.text('Account Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify Theme toggle button exists
    expect(find.byTooltip('Toggle Theme'), findsOneWidget);

    // Verify Action Buttons exist
    expect(find.text('Primary Trade Action (Market Buy)'), findsOneWidget);
  });
}
