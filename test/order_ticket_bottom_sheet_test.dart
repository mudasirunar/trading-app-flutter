import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/blocs/theme/theme_cubit.dart';
import 'package:trading_app/blocs/trading/trading_bloc.dart';
import 'package:trading_app/blocs/trading/trading_event.dart';
import 'package:trading_app/blocs/trading/trading_state.dart';
import 'package:trading_app/models/instrument_model.dart';
import 'package:trading_app/models/order_model.dart';
import 'package:trading_app/repositories/trading/trading_repository.dart';
import 'package:trading_app/services/storage/local_storage_service.dart';
import 'package:trading_app/views/trading/widgets/order_ticket_bottom_sheet.dart';

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
    volume: 52000000,
    avgVolume: 50000000,
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
  late TradingBloc tradingBloc;
  late ThemeCubit themeCubit;

  final testInstrument = createTestInstrument(
    symbol: 'AAPL',
    name: 'Apple Inc.',
    currentPrice: 150.0,
    change: 2.0,
    changePercentage: 1.35,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = LocalStorageService(preferences: prefs);
    await storageService.init();
    repository = TradingRepository(storage: storageService);
    tradingBloc = TradingBloc(repository: repository);
    themeCubit = ThemeCubit();
  });

  tearDown(() {
    tradingBloc.close();
    themeCubit.close();
  });

  Widget buildTestWidget({
    OrderSide initialSide = OrderSide.buy,
    InstrumentModel? instrument,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TradingBloc>.value(value: tradingBloc),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OrderTicketBottomSheet(
              instrument: instrument ?? testInstrument,
              initialSide: initialSide,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpLoadedTicket(
    WidgetTester tester, {
    OrderSide initialSide = OrderSide.buy,
    InstrumentModel? instrument,
  }) async {
    tradingBloc.add(const TradingInitialized());
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 60));
    });
    await tester.pumpWidget(buildTestWidget(
      initialSide: initialSide,
      instrument: instrument,
    ));
    await tester.pumpAndSettle();
  }

  group('OrderTicketBottomSheet Widget Tests', () {
    testWidgets('Renders instrument symbol, price, and Buy / Sell tabs', (tester) async {
      await pumpLoadedTicket(tester);

      expect(find.text('AAPL'), findsWidgets);
      expect(find.textContaining('150.00'), findsWidgets);
      expect(find.text('Buy AAPL'), findsWidgets);
      expect(find.text('Sell AAPL'), findsWidgets);
      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Limit'), findsOneWidget);
      expect(find.text('Stop-Loss'), findsOneWidget);
    });

    testWidgets('Toggling between Buy and Sell updates action button text', (tester) async {
      await pumpLoadedTicket(tester, initialSide: OrderSide.buy);

      expect(find.text('Buy 1 AAPL'), findsOneWidget);

      // Tap Sell tab
      await tester.tap(find.text('Sell AAPL').first);
      await tester.pumpAndSettle();

      // Since user has 0 shares, the button text reflects Insufficient Shares
      expect(find.text('Insufficient Shares'), findsOneWidget);
    });

    testWidgets('Selecting Limit order type reveals Limit Target Price input', (tester) async {
      await pumpLoadedTicket(tester);

      // Initially Market order: no Limit Price field
      expect(find.text('Limit Target Price'), findsNothing);

      // Tap Limit order chip
      await tester.tap(find.text('Limit'));
      await tester.pumpAndSettle();

      expect(find.text('Limit Target Price'), findsOneWidget);
    });

    testWidgets('Selecting Stop-Loss order type reveals Stop Trigger Price input', (tester) async {
      await pumpLoadedTicket(tester);

      expect(find.text('Stop Trigger Price'), findsNothing);

      // Tap Stop-Loss order chip
      await tester.tap(find.text('Stop-Loss'));
      await tester.pumpAndSettle();

      expect(find.text('Stop Trigger Price'), findsOneWidget);
    });

    testWidgets('Quantity stepper + and - buttons change quantity value', (tester) async {
      await pumpLoadedTicket(tester);

      // Default quantity is 1
      expect(find.text('1'), findsWidgets);

      // Tap + button
      final plusButton = find.byIcon(Icons.add);
      expect(plusButton, findsOneWidget);
      await tester.tap(plusButton);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);

      // Tap - button
      final minusButton = find.byIcon(Icons.remove);
      expect(minusButton, findsOneWidget);
      await tester.tap(minusButton);
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('Shows Insufficient Shares warning when attempting to sell with zero holdings', (tester) async {
      await pumpLoadedTicket(tester, initialSide: OrderSide.sell);

      expect(find.textContaining('Insufficient Shares'), findsWidgets);
    });

    testWidgets('Quick allocation chips calculate quantity for buy orders', (tester) async {
      await pumpLoadedTicket(tester);

      // Tap 25% chip ($25,000 / $150 = ~166 shares)
      await tester.tap(find.text('25%'));
      await tester.pumpAndSettle();

      final expectedQty = (100000.0 * 0.25 / 150.0).floor().toString();
      expect(find.text(expectedQty), findsWidgets);
    });

    testWidgets('Submitting Buy order executes trade and confirms order', (tester) async {
      await pumpLoadedTicket(tester);

      // Tap Buy 1 AAPL button
      await tester.tap(find.text('Buy 1 AAPL'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 60));
      });
      await tester.pumpAndSettle();

      // Verify trading bloc received order and processed holding
      final state = tradingBloc.state;
      expect(state, isA<TradingLoaded>());
      final loaded = state as TradingLoaded;
      expect(loaded.holdings.any((h) => h.symbol == 'AAPL'), isTrue);
      expect(loaded.virtualCash, equals(100000.0 - 150.0 - 1.0));
    });

    testWidgets('OrderTicketBottomSheet.show opens modal bottom sheet and displays ticket', (tester) async {
      tradingBloc.add(const TradingInitialized());
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 60));
      });

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<TradingBloc>.value(value: tradingBloc),
            BlocProvider<ThemeCubit>.value(value: themeCubit),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => OrderTicketBottomSheet.show(
                    ctx,
                    instrument: testInstrument,
                    initialSide: OrderSide.buy,
                  ),
                  child: const Text('Open Ticket'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Ticket'));
      await tester.pumpAndSettle();

      expect(find.text('AAPL'), findsWidgets);
      expect(find.text('Buy 1 AAPL'), findsOneWidget);
    });
  });
}
