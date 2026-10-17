import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/blocs/watchlist/watchlist_bloc.dart';
import 'package:trading_app/blocs/watchlist/watchlist_event.dart';
import 'package:trading_app/blocs/watchlist/watchlist_state.dart';
import 'package:trading_app/repositories/watchlist/watchlist_repository.dart';
import 'package:trading_app/services/storage/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;
  late WatchlistRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = LocalStorageService(preferences: prefs);
    await storageService.init();
    repository = WatchlistRepository(storageService: storageService);
  });

  group('WatchlistBloc Tests', () {
    test('Initial state is WatchlistsInitial', () {
      final bloc = WatchlistBloc(repository: repository);
      expect(bloc.state, equals(const WatchlistsInitial()));
    });

    blocTest<WatchlistBloc, WatchlistState>(
      'WatchlistsLoadRequested emits [WatchlistsLoading, WatchlistsLoaded] with default seeds',
      build: () => WatchlistBloc(repository: repository),
      act: (bloc) => bloc.add(const WatchlistsLoadRequested()),
      expect: () => [
        const WatchlistsLoading(),
        isA<WatchlistsLoaded>()
            .having((s) => s.watchlists.length, 'watchlists count', 3)
            .having((s) => s.activeWatchlistId, 'active id', 'default_tech_giants')
            .having((s) => s.isSymbolInWatchlist('default_tech_giants', 'AAPL'), 'contains AAPL', true),
      ],
    );

    blocTest<WatchlistBloc, WatchlistState>(
      'WatchlistCreated creates new watchlist and sets it active',
      build: () => WatchlistBloc(repository: repository),
      seed: () => const WatchlistsLoaded(
        watchlists: [],
        activeWatchlistId: '',
      ),
      act: (bloc) => bloc.add(const WatchlistCreated(name: 'Crypto & Forex')),
      expect: () => [
        isA<WatchlistsLoaded>()
            .having((s) => s.watchlists.any((w) => w.name == 'Crypto & Forex'), 'has created watchlist', true)
            .having((s) => s.activeWatchlist?.name, 'active watchlist name', 'Crypto & Forex'),
      ],
    );

    blocTest<WatchlistBloc, WatchlistState>(
      'WatchlistSymbolToggled toggles symbol presence in watchlist',
      build: () => WatchlistBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const WatchlistsLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        // NVDA is currently in default_tech_giants -> toggling removes it
        bloc.add(const WatchlistSymbolToggled(
          watchlistId: 'default_tech_giants',
          symbol: 'NVDA',
        ));
      },
      skip: 1, // Skip Loading
      expect: () => [
        isA<WatchlistsLoaded>().having((s) => s.isSymbolInWatchlist('default_tech_giants', 'NVDA'), 'has NVDA', true),
        isA<WatchlistsLoaded>().having((s) => s.isSymbolInWatchlist('default_tech_giants', 'NVDA'), 'has NVDA', false),
      ],
    );

    blocTest<WatchlistBloc, WatchlistState>(
      'WatchlistRenamed updates title correctly',
      build: () => WatchlistBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const WatchlistsLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const WatchlistRenamed(
          id: 'default_tech_giants',
          newName: 'Big Tech Leaders',
        ));
      },
      skip: 1, // Skip Loading
      expect: () => [
        isA<WatchlistsLoaded>().having((s) => s.activeWatchlist?.name, 'name', 'Tech Giants'),
        isA<WatchlistsLoaded>().having((s) => s.activeWatchlist?.name, 'name', 'Big Tech Leaders'),
      ],
    );

    blocTest<WatchlistBloc, WatchlistState>(
      'WatchlistDeleted deletes collection',
      build: () => WatchlistBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const WatchlistsLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const WatchlistDeleted(id: 'default_dividend'));
      },
      skip: 1, // Skip Loading
      expect: () => [
        isA<WatchlistsLoaded>().having((s) => s.watchlists.length, 'length', 3),
        isA<WatchlistsLoaded>()
            .having((s) => s.watchlists.length, 'length', 2)
            .having((s) => s.watchlists.any((w) => w.id == 'default_dividend'), 'has dividend', false),
      ],
    );
  });
}
