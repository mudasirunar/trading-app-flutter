import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/blocs/market/market_bloc.dart';
import 'package:trading_app/blocs/trading/trading_bloc.dart';
import 'package:trading_app/blocs/trading/trading_event.dart';
import 'package:trading_app/blocs/trading/trading_state.dart';
import 'package:trading_app/models/holding_model.dart';
import 'package:trading_app/models/order_model.dart';
import 'package:trading_app/models/transaction_model.dart';
import 'package:trading_app/repositories/market/market_repository.dart';
import 'package:trading_app/services/market/simulated_exchange_data_source.dart';
import 'package:trading_app/views/portfolio/portfolio_screen.dart';
import 'package:trading_app/views/portfolio/widgets/completed_order_card.dart';
import 'package:trading_app/views/portfolio/widgets/holding_card.dart';
import 'package:trading_app/views/portfolio/widgets/open_order_card.dart';
import 'package:trading_app/views/portfolio/widgets/portfolio_hero_card.dart';
import 'package:trading_app/views/portfolio/widgets/trade_receipt_dialog.dart';
import 'package:trading_app/views/portfolio/widgets/transaction_ledger_view.dart';

class TestTradingBloc extends Bloc<TradingEvent, TradingState>
    implements TradingBloc {
  final List<TradingEvent> addedEvents = [];

  TestTradingBloc(super.initialState) {
    on<TradingEvent>((event, emit) {
      addedEvents.add(event);
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SimulatedExchangeDataSource dataSource;
  late MarketRepository marketRepository;
  late MarketBloc marketBloc;

  setUp(() {
    dataSource = SimulatedExchangeDataSource(
      tickInterval: const Duration(hours: 1),
      randomSeed: 42,
    );
    marketRepository = MarketRepository(dataSource: dataSource);
    marketBloc = MarketBloc(marketRepository: marketRepository);
  });

  tearDown(() {
    marketBloc.close();
  });

  Widget createSubject({
    required TradingBloc tradingBloc,
    VoidCallback? onExploreMarkets,
  }) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<TradingBloc>.value(value: tradingBloc),
          BlocProvider<MarketBloc>.value(value: marketBloc),
        ],
        child: PortfolioScreen(
          onExploreMarkets: onExploreMarkets,
        ),
      ),
    );
  }

  group('PortfolioScreen Widget Tests', () {
    testWidgets('renders empty state when holdings are empty and invokes onExploreMarkets',
        (tester) async {
      bool exploreClicked = false;

      final testBloc = TestTradingBloc(
        const TradingLoaded(
          virtualCash: 100000.0,
          holdings: [],
          orders: [],
          transactions: [],
        ),
      );

      await tester.pumpWidget(createSubject(
        tradingBloc: testBloc,
        onExploreMarkets: () => exploreClicked = true,
      ));
      await tester.pumpAndSettle();

      // Check title and hero card
      expect(find.text('PORTFOLIO'), findsOneWidget);
      expect(find.byType(PortfolioHeroCard), findsOneWidget);
      expect(find.text('\$100,000.00'), findsNWidgets(2)); // Total and Cash

      // Check empty state
      expect(find.text('No Open Positions Yet'), findsOneWidget);
      expect(find.text('Explore Markets'), findsOneWidget);

      await tester.tap(find.text('Explore Markets'));
      expect(exploreClicked, isTrue);

      await testBloc.close();
    });

    testWidgets('renders populated holdings with correct metrics',
        (tester) async {
      const holding = HoldingModel(
        symbol: 'AAPL',
        quantity: 10.0,
        averageCost: 150.0,
        currentPrice: 180.0,
      );

      final testBloc = TestTradingBloc(
        const TradingLoaded(
          virtualCash: 98500.0,
          holdings: [holding],
          orders: [],
          transactions: [],
        ),
      );

      await tester.pumpWidget(createSubject(tradingBloc: testBloc));
      await tester.pumpAndSettle();

      // Check HoldingCard renders
      expect(find.byType(HoldingCard), findsOneWidget);
      expect(find.text('AAPL'), findsWidgets);
      expect(find.text('10 shares · \$150.00 avg'), findsOneWidget);
      expect(find.text('\$1,800.00'), findsWidgets); // Market value
      expect(find.text('+\$300.00 (+20.00%)'), findsWidgets);

      await testBloc.close();
    });

    testWidgets('switches to Orders tab and displays pending orders with cancel capability',
        (tester) async {
      final pendingOrder = OrderModel(
        id: 'ord-test-123',
        symbol: 'AAPL',
        side: OrderSide.buy,
        type: OrderType.limit,
        quantity: 5.0,
        limitPrice: 170.0,
        status: OrderStatus.pending,
        createdAt: DateTime(2026, 10, 18, 14, 30),
      );

      final testBloc = TestTradingBloc(
        TradingLoaded(
          virtualCash: 95000.0,
          holdings: const [],
          orders: [pendingOrder],
          transactions: const [],
        ),
      );

      await tester.pumpWidget(createSubject(tradingBloc: testBloc));
      await tester.pumpAndSettle();

      // Tap Orders tab
      await tester.tap(find.text('Orders (1)'));
      await tester.pumpAndSettle();

      // Verify OpenOrderCard renders
      expect(find.byType(OpenOrderCard), findsOneWidget);
      expect(find.text('BUY · LIMIT'), findsOneWidget);
      expect(find.text('5 shares'), findsOneWidget);
      expect(find.text('\$170.00'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget);

      // Tap Cancel Order button
      await tester.tap(find.text('Cancel Order'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Cancel Order?'), findsOneWidget);
      expect(find.text('Yes, Cancel Order'), findsOneWidget);

      await tester.tap(find.text('Yes, Cancel Order'));
      await tester.pumpAndSettle();

      // Verify OrderCancelled event was added
      expect(
        testBloc.addedEvents.whereType<OrderCancelled>().any((e) => e.orderId == 'ord-test-123'),
        isTrue,
      );

      await testBloc.close();
    });

    testWidgets('Completed Orders sub-tab displays history and opens TradeReceiptDialog',
        (tester) async {
      final completedOrder = OrderModel(
        id: 'rec-xyz-789',
        symbol: 'AAPL',
        side: OrderSide.buy,
        type: OrderType.market,
        quantity: 10.0,
        filledQuantity: 10.0,
        executionPrice: 180.0,
        fees: 1.0,
        status: OrderStatus.filled,
        createdAt: DateTime(2026, 10, 18, 10, 0),
        executedAt: DateTime(2026, 10, 18, 10, 0, 2),
      );

      final testBloc = TestTradingBloc(
        TradingLoaded(
          virtualCash: 98199.0,
          holdings: const [],
          orders: [completedOrder],
          transactions: const [],
        ),
      );

      await tester.pumpWidget(createSubject(tradingBloc: testBloc));
      await tester.pumpAndSettle();

      // Tap Orders tab
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();

      // Tap Completed sub-tab
      await tester.tap(find.text('Completed (1)'));
      await tester.pumpAndSettle();

      expect(find.byType(CompletedOrderCard), findsOneWidget);
      expect(find.text('10 shs @ \$180.00'), findsOneWidget);
      expect(find.text('FILLED'), findsOneWidget);

      // Tap the completed order card to open TradeReceiptDialog
      await tester.tap(find.byType(CompletedOrderCard));
      await tester.pumpAndSettle();

      expect(find.byType(TradeReceiptDialog), findsOneWidget);
      expect(find.text('Trade Execution Receipt'), findsOneWidget);
      expect(find.text('Net Settled Capital'), findsOneWidget);
      expect(find.text('\$1,801.00'), findsOneWidget); // 1800 gross + 1 fee
      expect(find.text('Close Receipt'), findsOneWidget);

      await tester.tap(find.text('Close Receipt'));
      await tester.pumpAndSettle();
      expect(find.byType(TradeReceiptDialog), findsNothing);

      await testBloc.close();
    });

    testWidgets('switches to Ledger tab and displays transactions',
        (tester) async {
      final depositTx = TransactionModel(
        id: 'tx-1',
        type: TransactionType.deposit,
        amount: 100000.0,
        timestamp: DateTime(2026, 10, 18, 9, 0),
        reference: 'Initial Deposit',
      );
      final buyTx = TransactionModel(
        id: 'tx-2',
        type: TransactionType.buy,
        amount: -1801.0,
        symbol: 'AAPL',
        quantity: 10.0,
        price: 180.0,
        fees: 1.0,
        timestamp: DateTime(2026, 10, 18, 10, 0),
        reference: 'Order execution',
      );

      final testBloc = TestTradingBloc(
        TradingLoaded(
          virtualCash: 98199.0,
          holdings: const [],
          orders: const [],
          transactions: [depositTx, buyTx],
        ),
      );

      await tester.pumpWidget(createSubject(tradingBloc: testBloc));
      await tester.pumpAndSettle();

      // Tap Ledger tab
      await tester.tap(find.text('Ledger'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionLedgerView), findsOneWidget);
      expect(find.text('Deposit'), findsOneWidget);
      expect(find.text('+\$100,000.00'), findsOneWidget);
      expect(find.text('Buy · AAPL'), findsOneWidget);
      expect(find.text('-\$1,801.00'), findsOneWidget);

      await testBloc.close();
    });

    testWidgets('Reset Portfolio icon button triggers confirmation and event',
        (tester) async {
      final testBloc = TestTradingBloc(
        const TradingLoaded(
          virtualCash: 50000.0,
          holdings: [],
          orders: [],
          transactions: [],
        ),
      );

      await tester.pumpWidget(createSubject(tradingBloc: testBloc));
      await tester.pumpAndSettle();

      // Tap reset icon in AppBar
      await tester.tap(find.byIcon(Icons.restart_alt_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Reset Virtual Account?'), findsOneWidget);
      expect(find.text('Reset Account'), findsOneWidget);

      await tester.tap(find.text('Reset Account'));
      await tester.pumpAndSettle();

      expect(testBloc.addedEvents.whereType<VirtualAccountReset>().isNotEmpty, isTrue);

      await testBloc.close();
    });
  });
}
