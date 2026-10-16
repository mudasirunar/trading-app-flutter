import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/models/candle_model.dart';
import 'package:trading_app/views/instrument_detail/widgets/interactive_financial_chart.dart';

void main() {
  group('InteractiveFinancialChart Widget Tests', () {
    late List<CandleModel> mockCandles;

    setUp(() {
      final base = DateTime(2026, 10, 16, 10, 0);
      mockCandles = List.generate(20, (i) {
        final time = base.add(Duration(minutes: 5 * i));
        final open = 150.0 + i;
        final close = 151.0 + i;
        final high = 152.0 + i;
        final low = 149.0 + i;
        final volume = 10000.0 + (i * 500);
        return CandleModel(
          timestamp: time,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        );
      });
    });

    testWidgets('Renders chart canvas, timeframe buttons, and toggle buttons', (
      WidgetTester tester,
    ) async {
      MarketTimeframe selectedTf = MarketTimeframe.oneDay;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveFinancialChart(
              candles: mockCandles,
              activeTimeframe: selectedTf,
              onTimeframeChanged: (tf) => selectedTf = tf,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check all timeframe labels
      expect(find.text('1D'), findsOneWidget);
      expect(find.text('1W'), findsOneWidget);
      expect(find.text('1M'), findsOneWidget);
      expect(find.text('3M'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);

      // Check chart style toggle icons
      expect(find.byIcon(Icons.candlestick_chart_rounded), findsOneWidget);
      expect(find.byIcon(Icons.show_chart_rounded), findsOneWidget);

      // Check that the CustomPaint canvas is rendered
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Tapping timeframe triggers onTimeframeChanged callback', (
      WidgetTester tester,
    ) async {
      MarketTimeframe selectedTf = MarketTimeframe.oneDay;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveFinancialChart(
              candles: mockCandles,
              activeTimeframe: selectedTf,
              onTimeframeChanged: (tf) => selectedTf = tf,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 1M
      await tester.tap(find.text('1M'));
      await tester.pumpAndSettle();

      expect(selectedTf, equals(MarketTimeframe.oneMonth));
    });

    testWidgets('Toggling display mode switches between Candlestick and Line Area', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveFinancialChart(
              candles: mockCandles,
              activeTimeframe: MarketTimeframe.oneDay,
              onTimeframeChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Line Area icon
      await tester.tap(find.byIcon(Icons.show_chart_rounded));
      await tester.pumpAndSettle();

      // Verify still renders without crashing
      expect(find.byType(CustomPaint), findsWidgets);

      // Switch back to Candlestick
      await tester.tap(find.byIcon(Icons.candlestick_chart_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Gesture scrubbing over chart invokes onCandleScrubbed callback', (
      WidgetTester tester,
    ) async {
      CandleModel? scrubbedCandle;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveFinancialChart(
              candles: mockCandles,
              activeTimeframe: MarketTimeframe.oneDay,
              onTimeframeChanged: (_) {},
              onCandleScrubbed: (c) => scrubbedCandle = c,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the CustomPaint canvas of the chart
      final canvasFinder = find.byType(CustomPaint).first;

      // Simulate a drag on the chart canvas
      final center = tester.getCenter(canvasFinder);
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();

      expect(scrubbedCandle, isNotNull);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(scrubbedCandle, isNull);
    });
  });
}
