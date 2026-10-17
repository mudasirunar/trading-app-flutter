import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/widgets/market_search_bar.dart';

void main() {
  group('MarketSearchBar Widget Tests', () {
    testWidgets('Renders hint text, search icon, and handles text input', (
      tester,
    ) async {
      final controller = TextEditingController();
      String changedText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarketSearchBar(
              controller: controller,
              hintText: 'Search markets...',
              onChanged: (val) => changedText = val,
            ),
          ),
        ),
      );

      expect(find.text('Search markets...'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'AAPL');
      await tester.pumpAndSettle();

      expect(changedText, equals('AAPL'));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('Tapping clear button clears text and invokes onClear callback', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'NVDA');
      bool clearInvoked = false;
      String lastChanged = 'NVDA';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarketSearchBar(
              controller: controller,
              hintText: 'Search...',
              onChanged: (val) => lastChanged = val,
              onClear: () => clearInvoked = true,
            ),
          ),
        ),
      );

      expect(find.text('NVDA'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(lastChanged, isEmpty);
      expect(clearInvoked, isTrue);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });
  });
}
