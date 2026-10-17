import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/blocs/market/market_bloc.dart';
import 'package:trading_app/blocs/market/market_event.dart';
import 'package:trading_app/blocs/market/market_state.dart';
import 'package:trading_app/models/candle_model.dart';
import 'package:trading_app/models/instrument_model.dart';
import 'package:trading_app/repositories/market/market_repository.dart';
import 'package:trading_app/services/market/simulated_exchange_data_source.dart';

void main() {
  group('MarketBloc Tests', () {
    late SimulatedExchangeDataSource dataSource;
    late MarketRepository repository;

    setUp(() {
      dataSource = SimulatedExchangeDataSource(
        tickInterval: const Duration(hours: 1), // Manual tick control in tests
        randomSeed: 99,
      );
      repository = MarketRepository(dataSource: dataSource);
    });

    tearDown(() {
      repository.dispose();
    });

    test('Initial state is MarketInitial', () {
      final bloc = MarketBloc(marketRepository: repository);
      expect(bloc.state, equals(const MarketInitial()));
      bloc.close();
    });

    blocTest<MarketBloc, MarketState>(
      'MarketStarted emits [MarketLoading, MarketLoaded] with 30 assets and initial chart candles',
      build: () => MarketBloc(marketRepository: repository),
      act: (bloc) => bloc.add(const MarketStarted(defaultSymbol: 'AAPL')),
      expect: () => [
        const MarketLoading(),
        isA<MarketLoaded>()
            .having((s) => s.instruments.length, 'instruments count', 30)
            .having((s) => s.selectedSymbol, 'selectedSymbol', 'AAPL')
            .having((s) => s.selectedCandles.length, 'candles count', 78)
            .having((s) => s.isFeedLive, 'isFeedLive', isTrue)
            .having(
              (s) => s.feedVenue,
              'feedVenue',
              'Simulated Exchange Feed • Real-Time',
            ),
      ],
    );

    blocTest<MarketBloc, MarketState>(
      'MarketSearchQueryChanged filters instruments by ticker symbol and company name',
      build: () => MarketBloc(marketRepository: repository),
      seed: () {
        final now = DateTime.now();
        return MarketLoaded(
          instruments: [
            InstrumentModel(
              symbol: 'AAPL',
              name: 'Apple Inc.',
              exchange: 'NASDAQ',
              sector: 'Technology',
              currentPrice: 230.0,
              openPrice: 228.0,
              high24h: 232.0,
              low24h: 227.0,
              previousClose: 228.0,
              change: 2.0,
              changePercentage: 0.88,
              bidPrice: 229.95,
              askPrice: 230.05,
              spread: 0.10,
              bidSize: 500,
              askSize: 500,
              volume: 1000000,
              avgVolume: 2000000,
              marketCap: 3500000000000,
              peRatio: 33.0,
              eps: 6.5,
              beta: 1.0,
              dividendYield: 0.5,
              week52High: 235.0,
              week52Low: 165.0,
              sparkline: const [228.0, 230.0],
              lastUpdated: now,
            ),
            InstrumentModel(
              symbol: 'NVDA',
              name: 'NVIDIA Corporation',
              exchange: 'NASDAQ',
              sector: 'Semiconductors',
              currentPrice: 135.0,
              openPrice: 130.0,
              high24h: 136.0,
              low24h: 129.0,
              previousClose: 130.0,
              change: 5.0,
              changePercentage: 3.85,
              bidPrice: 134.95,
              askPrice: 135.05,
              spread: 0.10,
              bidSize: 500,
              askSize: 500,
              volume: 2000000,
              avgVolume: 3000000,
              marketCap: 3300000000000,
              peRatio: 55.0,
              eps: 2.4,
              beta: 1.6,
              dividendYield: 0.03,
              week52High: 140.0,
              week52Low: 40.0,
              sparkline: const [130.0, 135.0],
              lastUpdated: now,
            ),
          ],
          searchResults: const [],
          selectedSymbol: 'AAPL',
          selectedCandles: const [],
          lastTickTimestamp: now,
        );
      },
      act: (bloc) => bloc.add(const MarketSearchQueryChanged(query: 'NVD')),
      expect: () => [
        isA<MarketLoaded>()
            .having((s) => s.searchResults.length, 'search count', 1)
            .having((s) => s.searchResults.first.symbol, 'symbol', 'NVDA'),
      ],
    );

    blocTest<MarketBloc, MarketState>(
      'MarketTimeframeSelected loads candles for the selected timeframe',
      build: () => MarketBloc(marketRepository: repository),
      seed: () {
        final now = DateTime.now();
        return MarketLoaded(
          instruments: const [],
          searchResults: const [],
          selectedSymbol: 'AAPL',
          selectedCandles: const [],
          activeTimeframe: MarketTimeframe.oneDay,
          lastTickTimestamp: now,
        );
      },
      act: (bloc) => bloc.add(
        const MarketTimeframeSelected(
          symbol: 'AAPL',
          timeframe: MarketTimeframe.oneYear,
        ),
      ),
      expect: () => [
        isA<MarketLoaded>()
            .having((s) => s.activeTimeframe, 'timeframe', MarketTimeframe.oneYear)
            .having((s) => s.selectedCandles.length, 'candle count', 52),
      ],
    );

    blocTest<MarketBloc, MarketState>(
      'MarketFeedPaused and MarketFeedResumed toggle feed live state',
      build: () => MarketBloc(marketRepository: repository),
      seed: () {
        final now = DateTime.now();
        return MarketLoaded(
          instruments: const [],
          searchResults: const [],
          selectedSymbol: 'AAPL',
          selectedCandles: const [],
          isFeedLive: true,
          lastTickTimestamp: now,
        );
      },
      act: (bloc) {
        bloc.add(const MarketFeedPaused());
        bloc.add(const MarketFeedResumed());
      },
      expect: () => [
        isA<MarketLoaded>().having((s) => s.isFeedLive, 'isFeedLive', isFalse),
        isA<MarketLoaded>().having((s) => s.isFeedLive, 'isFeedLive', isTrue),
      ],
    );
  });
}
