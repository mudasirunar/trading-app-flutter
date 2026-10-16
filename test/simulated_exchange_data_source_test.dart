import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/models/candle_model.dart';
import 'package:trading_app/services/market/simulated_exchange_data_source.dart';

void main() {
  group('SimulatedExchangeDataSource Tests', () {
    late SimulatedExchangeDataSource dataSource;

    setUp(() {
      dataSource = SimulatedExchangeDataSource(
        tickInterval: const Duration(milliseconds: 50),
        randomSeed: 42,
      );
    });

    tearDown(() {
      dataSource.dispose();
    });

    test('Initial catalog seeds 15 premier institutional assets', () async {
      final instruments = await dataSource.fetchInitialInstruments();
      expect(instruments.length, equals(15));

      final symbols = instruments.map((i) => i.symbol).toSet();
      expect(
        symbols,
        containsAll([
          'AAPL',
          'MSFT',
          'NVDA',
          'GOOGL',
          'AMZN',
          'META',
          'TSLA',
          'BRK.B',
          'JPM',
          'V',
          'LLY',
          'JNJ',
          'XOM',
          'WMT',
          'MCD',
        ]),
      );

      for (final instrument in instruments) {
        expect(instrument.currentPrice, greaterThan(0.0));
        expect(instrument.bidPrice, lessThanOrEqualTo(instrument.askPrice));
        expect(instrument.spread, greaterThan(0.0));
        expect(instrument.high24h, greaterThanOrEqualTo(instrument.low24h));
        expect(instrument.week52High, greaterThanOrEqualTo(instrument.week52Low));
        expect(instrument.sparkline, isNotEmpty);
        expect(
          instrument.feedVenue,
          equals('Simulated Exchange Feed • Real-Time'),
        );
        expect(
          ['NASDAQ', 'NYSE'].contains(instrument.exchange),
          isTrue,
        );
      }
    });

    test('Historical Candlestick generation satisfies strict financial invariants', () async {
      for (final timeframe in MarketTimeframe.values) {
        final candles = await dataSource.fetchCandles('AAPL', timeframe);
        expect(candles.length, equals(timeframe.targetCandleCount));

        for (final candle in candles) {
          expect(candle.high, greaterThanOrEqualTo(candle.low));
          expect(candle.high, greaterThanOrEqualTo(candle.open));
          expect(candle.high, greaterThanOrEqualTo(candle.close));
          expect(candle.low, lessThanOrEqualTo(candle.open));
          expect(candle.low, lessThanOrEqualTo(candle.close));
          expect(candle.volume, greaterThan(0));
          expect(candle.wickRange, greaterThanOrEqualTo(0));
          expect(candle.bodyHeight, greaterThanOrEqualTo(0));
        }
      }
    });

    test('Live quote stream emits updating ticks with valid price invariants', () async {
      final tickFuture = dataSource.quoteStream.first;
      dataSource.startStream();

      final ticks = await tickFuture;
      expect(ticks.length, equals(15));

      for (final tick in ticks) {
        expect(tick.currentPrice, greaterThan(0.0));
        expect(tick.bidPrice, lessThanOrEqualTo(tick.askPrice));
        expect(tick.high24h, greaterThanOrEqualTo(tick.low24h));
        expect(tick.sparkline.length, inInclusiveRange(1, 26));
      }
    });

    test('Active candlestick mutates dynamically on incoming ticks', () async {
      // First load candles for AAPL
      final initialCandles = await dataSource.fetchCandles('AAPL', MarketTimeframe.oneDay);
      final initialLastCandle = initialCandles.last;

      // Start stream and wait for at least one tick
      final tickFuture = dataSource.quoteStream.first;
      dataSource.startStream();
      final tick = await tickFuture;
      expect(tick, isNotEmpty);

      // Verify that the cached candle was mutated
      final updatedCandles = await dataSource.fetchCandles('AAPL', MarketTimeframe.oneDay);
      final updatedLastCandle = updatedCandles.last;

      expect(updatedLastCandle.timestamp, equals(initialLastCandle.timestamp));
      expect(updatedLastCandle.volume, greaterThan(initialLastCandle.volume));
    });
  });
}
