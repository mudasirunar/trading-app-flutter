import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/widgets/app_snack_bar.dart';

void main() {
  group('AppSnackBar Widget Tests', () {
    testWidgets('shows custom snackbar with title, message, and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppSnackBar.showSuccess(
                    context,
                    'Paper trade executed',
                    title: 'Trade Confirmed',
                  );
                },
                child: const Text('Show Snack'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Trade Confirmed'), findsNothing);
      expect(find.text('Paper trade executed'), findsNothing);

      await tester.tap(find.text('Show Snack'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Trade Confirmed'), findsOneWidget);
      expect(find.text('Paper trade executed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Verify timer indicator progresses
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Trade Confirmed'), findsOneWidget);

      // Verify dismiss button works
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Trade Confirmed'), findsNothing);
    });

    testWidgets('supports action button and callback', (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppSnackBar.show(
                    context,
                    message: 'Low margin balance',
                    title: 'Margin Alert',
                    type: AppSnackBarType.warning,
                    actionLabel: 'Deposit',
                    onAction: () => actionTriggered = true,
                  );
                },
                child: const Text('Trigger Alert'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Alert'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Deposit'), findsOneWidget);
      await tester.tap(find.text('Deposit'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });

    testWidgets('renders all variant types without errors', (tester) async {
      for (final type in AppSnackBarType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppSnackBar.show(
                      context,
                      message: 'Test message for $type',
                      type: type,
                    );
                  },
                  child: Text('Type $type'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Type $type'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Test message for $type'), findsOneWidget);

        // Dismiss
        ScaffoldMessenger.of(tester.element(find.text('Type $type'))).hideCurrentSnackBar();
        await tester.pumpAndSettle();
      }
    });
  });
}
