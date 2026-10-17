import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/blocs/market/market_bloc.dart';
import 'package:trading_app/blocs/market/market_event.dart';
import 'package:trading_app/blocs/watchlist/watchlist_bloc.dart';
import 'package:trading_app/blocs/watchlist/watchlist_event.dart';
import 'package:trading_app/repositories/market/market_repository.dart';
import 'package:trading_app/repositories/watchlist/watchlist_repository.dart';
import 'package:trading_app/services/market/simulated_exchange_data_source.dart';
import 'package:trading_app/services/storage/local_storage_service.dart';
import 'package:trading_app/views/watchlist/watchlist_screen.dart';
import 'package:trading_app/views/watchlist/widgets/watchlist_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;
  late WatchlistRepository watchlistRepository;
  late SimulatedExchangeDataSource marketDataSource;
  late MarketRepository marketRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = LocalStorageService(preferences: prefs);
    await storageService.init();
    watchlistRepository = WatchlistRepository(storageService: storageService);
    marketDataSource = SimulatedExchangeDataSource(
      tickInterval: const Duration(hours: 1),
      randomSeed: 42,
    );
    marketRepository = MarketRepository(dataSource: marketDataSource);
  });

  tearDown(() {
    marketRepository.dispose();
  });

  Widget buildTestableWidget({VoidCallback? onNavigateToSearch}) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<WatchlistRepository>.value(value: watchlistRepository),
        RepositoryProvider<MarketRepository>.value(value: marketRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<WatchlistBloc>(
            create: (_) => WatchlistBloc(repository: watchlistRepository)
              ..add(const WatchlistsLoadRequested()),
          ),
          BlocProvider<MarketBloc>(
            create: (_) => MarketBloc(marketRepository: marketRepository)
              ..add(const MarketStarted()),
          ),
        ],
        child: MaterialApp(
          home: WatchlistScreen(
            onNavigateToSearch: onNavigateToSearch,
          ),
        ),
      ),
    );
  }

  group('WatchlistScreen Widget Tests', () {
    testWidgets('Renders AppBar title and Action buttons', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Watchlists'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsWidgets);
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    });

    testWidgets('Renders all default watchlist tabs with symbol counts', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tech Giants'), findsOneWidget);
      expect(find.text('High Beta'), findsOneWidget);
      expect(find.text('Dividend Growth'), findsOneWidget);
      expect(find.text('New List'), findsOneWidget);
    });

    testWidgets('Renders asset cards for default Tech Giants watchlist', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Check for assets seeded in Tech Giants
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('MSFT'), findsOneWidget);
      expect(find.text('GOOGL'), findsOneWidget);
    });

    testWidgets('Tapping tab switches active collection', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap on High Beta
      await tester.tap(find.text('High Beta'));
      await tester.pumpAndSettle();

      // High Beta assets should now be visible
      expect(find.text('TSLA'), findsWidgets);
    });

    testWidgets('Search bar filters watchlist items and can be cleared', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(WatchlistCard, 'AAPL'), findsOneWidget);
      expect(find.widgetWithText(WatchlistCard, 'MSFT'), findsOneWidget);

      // Filter by 'AAPL'
      await tester.enterText(find.byType(TextField), 'AAPL');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(WatchlistCard, 'AAPL'), findsOneWidget);
      expect(find.widgetWithText(WatchlistCard, 'MSFT'), findsNothing);

      // Filter by nonexistent ticker
      await tester.enterText(find.byType(TextField), 'NONEXISTENT');
      await tester.pumpAndSettle();

      expect(find.text('No matching instruments'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      // Clear search via button
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(WatchlistCard, 'AAPL'), findsOneWidget);
      expect(find.widgetWithText(WatchlistCard, 'MSFT'), findsOneWidget);
    });

    testWidgets('Smart brand aliases match instruments in watchlist (e.g. iphone -> AAPL)', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Search by brand keyword "iphone"
      await tester.enterText(find.byType(TextField), 'iphone');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(WatchlistCard, 'AAPL'), findsOneWidget);
      expect(find.widgetWithText(WatchlistCard, 'MSFT'), findsNothing);

      // Search by brand keyword "xbox"
      await tester.enterText(find.byType(TextField), 'xbox');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(WatchlistCard, 'MSFT'), findsOneWidget);
      expect(find.widgetWithText(WatchlistCard, 'AAPL'), findsNothing);
    });
  });
}
