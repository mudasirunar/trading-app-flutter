import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/blocs/trading/trading_bloc.dart';
import 'package:trading_app/blocs/trading/trading_event.dart';
import 'package:trading_app/blocs/trading/trading_state.dart';
import 'package:trading_app/models/instrument_model.dart';
import 'package:trading_app/models/order_model.dart';
import 'package:trading_app/repositories/trading/trading_repository.dart';
import 'package:trading_app/services/storage/local_storage_service.dart';

InstrumentModel createTestInstrument({
  required String symbol,
  required String name,
  required double currentPrice,
  required double change,
  required double changePercentage,
}) {
  return InstrumentModel(
    symbol: symbol,
    name: name,
    exchange: 'NASDAQ',
    sector: 'Technology',
    currentPrice: currentPrice,
    openPrice: currentPrice - change,
    high24h: currentPrice + 2.0,
    low24h: currentPrice - 2.0,
    previousClose: currentPrice - change,
    change: change,
    changePercentage: changePercentage,
    bidPrice: currentPrice - 0.05,
    askPrice: currentPrice + 0.05,
    spread: 0.10,
    bidSize: 100,
    askSize: 100,
    volume: 50000000,
    avgVolume: 45000000,
    marketCap: 2800000000000,
    peRatio: 30.0,
    eps: 6.0,
    beta: 1.0,
    dividendYield: 0.5,
    week52High: 180.0,
    week52Low: 120.0,
    sparkline: [currentPrice - 2, currentPrice],
    lastUpdated: DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;
  late TradingRepository repository;

  final testAapl = createTestInstrument(
    symbol: 'AAPL',
    name: 'Apple Inc.',
    currentPrice: 150.0,
    change: 2.0,
    changePercentage: 1.35,
  );

  final testTsla = createTestInstrument(
    symbol: 'TSLA',
    name: 'Tesla Inc.',
    currentPrice: 200.0,
    change: 2.0,
    changePercentage: 1.01,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = LocalStorageService(preferences: prefs);
    await storageService.init();
    repository = TradingRepository(storage: storageService);
  });

  group('TradingBloc Unit Tests', () {
    test('Initial state is TradingInitial', () {
      final bloc = TradingBloc(repository: repository);
      expect(bloc.state, equals(const TradingInitial()));
      bloc.close();
    });

    blocTest<TradingBloc, TradingState>(
      r'TradingInitialized loads initial $100k virtual cash and empty collections',
      build: () => TradingBloc(repository: repository),
      act: (bloc) => bloc.add(const TradingInitialized()),
      expect: () => [
        const TradingLoading(),
        isA<TradingLoaded>()
            .having((s) => s.virtualCash, 'virtualCash', 100000.0)
            .having((s) => s.holdings, 'holdings', isEmpty)
            .having((s) => s.orders, 'orders', isEmpty)
            .having((s) => s.transactions, 'transactions', isEmpty)
            .having((s) => s.totalPortfolioValue, 'portfolioValue', 100000.0),
      ],
    );

    blocTest<TradingBloc, TradingState>(
      'OrderSubmitted market buy executes immediately, deducts cash, creates holding',
      build: () => TradingBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const TradingInitialized());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(OrderSubmitted(
          instrument: testAapl,
          side: OrderSide.buy,
          type: OrderType.market,
          quantity: 10,
        ));
      },
      expect: () => [
        const TradingLoading(),
        isA<TradingLoaded>().having((s) => s.virtualCash, 'initial cash', 100000.0),
        isA<TradingLoaded>()
            .having((s) => s.virtualCash, 'remaining cash', 100000.0 - 1500.0 - 1.0)
            .having((s) => s.holdings.length, 'holdings length', 1)
            .having((s) => s.holdings.first.symbol, 'holding symbol', 'AAPL')
            .having((s) => s.holdings.first.quantity, 'holding quantity', 10.0)
            .having((s) => s.holdings.first.averageCost, 'holding avgCost', 150.0)
            .having((s) => s.completedOrders.length, 'completed orders', 1)
            .having((s) => s.completedOrders.first.status, 'status', OrderStatus.filled)
            .having((s) => s.transactions.length, 'transactions', 1),
      ],
    );

    blocTest<TradingBloc, TradingState>(
      'OrderSubmitted market buy with insufficient funds emits TradingActionFailure',
      build: () => TradingBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const TradingInitialized());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(OrderSubmitted(
          instrument: testAapl,
          side: OrderSide.buy,
          type: OrderType.market,
          quantity: 1000, // 1000 * $150 = $150,000 > $100k
        ));
      },
      expect: () => [
        const TradingLoading(),
        isA<TradingLoaded>(),
        isA<TradingActionFailure>().having(
          (f) => f.errorMessage,
          'failure message',
          contains('Insufficient buying power'),
        ),
        isA<TradingLoaded>(), // re-emitted previous state
      ],
    );

    blocTest<TradingBloc, TradingState>(
      'OrderSubmitted market sell decrements holding and credits cash',
      build: () => TradingBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const TradingInitialized());
        await Future.delayed(const Duration(milliseconds: 50));
        // Buy 10 AAPL @ $150 (Cost: $1500 + $1 fee)
        bloc.add(OrderSubmitted(
          instrument: testAapl,
          side: OrderSide.buy,
          type: OrderType.market,
          quantity: 10,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        // Sell 4 AAPL @ $150 (Proceeds: $600 - $1 fee = $599)
        bloc.add(OrderSubmitted(
          instrument: testAapl,
          side: OrderSide.sell,
          type: OrderType.market,
          quantity: 4,
        ));
      },
      expect: () => [
        const TradingLoading(),
        isA<TradingLoaded>(), // initial loaded
        isA<TradingLoaded>(), // after buy
        isA<TradingLoaded>()
            .having((s) => s.virtualCash, 'cash after sell', (100000.0 - 1501.0) + 599.0)
            .having((s) => s.holdings.first.quantity, 'remaining shares', 6.0)
            .having((s) => s.transactions.length, 'transactions count', 2),
      ],
    );

    blocTest<TradingBloc, TradingState>(
      'OrderSubmitted limit buy locks cash and reserves purchasing power',
      build: () => TradingBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const TradingInitialized());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(OrderSubmitted(
          instrument: testTsla,
          side: OrderSide.buy,
          type: OrderType.limit,
          quantity: 10,
          limitPrice: 190.0, // $1,900 + $1 fee locked
        ));
      },
      expect: () => [
        const TradingLoading(),
        isA<TradingLoaded>(),
        isA<TradingLoaded>()
            .having((s) => s.virtualCash, 'cash after lock', 100000.0 - 1901.0)
            .having((s) => s.pendingOrders.length, 'pending orders count', 1)
            .having((s) => s.pendingOrders.first.status, 'status', OrderStatus.pending)
            .having((s) => s.holdings, 'holdings remains empty', isEmpty),
      ],
    );

    blocTest<TradingBloc, TradingState>(
      'OrderCancelled refunds locked cash for pending Buy Limit',
      build: () => TradingBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const TradingInitialized());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(OrderSubmitted(
          instrument: testTsla,
          side: OrderSide.buy,
          type: OrderType.limit,
          quantity: 5,
          limitPrice: 180.0, // $900 + $1 fee locked
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        final state = bloc.state as TradingLoaded;
        final pendingOrderId = state.pendingOrders.first.id;
        bloc.add(OrderCancelled(orderId: pendingOrderId));
      },
      expect: () => [
        const TradingLoading(),
        isA<TradingLoaded>(),
        isA<TradingLoaded>().having((s) => s.virtualCash, 'cash after limit placement', 100000.0 - 901.0),
        isA<TradingLoaded>()
            .having((s) => s.virtualCash, 'cash refunded', 100000.0)
            .having((s) => s.pendingOrders, 'pending orders empty', isEmpty)
            .having((s) => s.completedOrders.first.status, 'order cancelled', OrderStatus.cancelled),
      ],
    );

    blocTest<TradingBloc, TradingState>(
      'MarketTickEvaluated fills Buy Limit order when tick price drops to or below limit price',
      build: () => TradingBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const TradingInitialized());
        await Future.delayed(const Duration(milliseconds: 50));
        // Buy limit: 10 AAPL @ $145 (Reserved = $1450 + $1 = $1451, Cash = $98,549)
        bloc.add(OrderSubmitted(
          instrument: testAapl,
          side: OrderSide.buy,
          type: OrderType.limit,
          quantity: 10,
          limitPrice: 145.0,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        // Market drops to $142 (Price improvement: executed @ $142, refund $3/share = $30)
        bloc.add(MarketTickEvaluated(
          instrument: testAapl.copyWith(currentPrice: 142.0),
        ));
      },
      expect: () => [
        const TradingLoading(),
        isA<TradingLoaded>(),
        isA<TradingLoaded>().having((s) => s.virtualCash, 'cash after limit lock', 100000.0 - 1451.0),
        isA<TradingLoaded>()
            .having((s) => s.pendingOrders, 'pending orders filled', isEmpty)
            .having((s) => s.completedOrders.length, 'completed order count', 1)
            .having((s) => s.completedOrders.first.status, 'order filled', OrderStatus.filled)
            .having((s) => s.completedOrders.first.executionPrice, 'executed at tick price', 142.0)
            .having((s) => s.virtualCash, 'refunded price improvement', (100000.0 - 1451.0) + 30.0)
            .having((s) => s.holdings.length, 'holding created', 1)
            .having((s) => s.holdings.first.quantity, 'shares', 10.0)
            .having((s) => s.holdings.first.averageCost, 'cost', 142.0),
      ],
    );

    blocTest<TradingBloc, TradingState>(
      r'VirtualAccountReset restores $100k cash and clears all active positions',
      build: () => TradingBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const TradingInitialized());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(OrderSubmitted(
          instrument: testAapl,
          side: OrderSide.buy,
          type: OrderType.market,
          quantity: 5,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const VirtualAccountReset());
      },
      expect: () => [
        const TradingLoading(),
        isA<TradingLoaded>(),
        isA<TradingLoaded>().having((s) => s.holdings.length, 'positions after buy', 1),
        const TradingLoading(),
        isA<TradingLoaded>()
            .having((s) => s.virtualCash, 'cash reset', 100000.0)
            .having((s) => s.holdings, 'holdings cleared', isEmpty)
            .having((s) => s.orders, 'orders cleared', isEmpty)
            .having((s) => s.transactions.length, 'seed transaction', 1),
      ],
    );
  });
}
