import '../../models/watchlist_model.dart';
import '../../services/storage/i_storage_service.dart';
import 'i_watchlist_repository.dart';

/// Concrete implementation of [IWatchlistRepository] using [IStorageService].
class WatchlistRepository implements IWatchlistRepository {
  WatchlistRepository({required IStorageService storageService})
      : _storage = storageService;

  final IStorageService _storage;

  static const String _kWatchlistsKey = 'user_watchlists';
  static const String _kActiveWatchlistIdKey = 'active_watchlist_id';

  static List<WatchlistModel> get _defaultSeeds => [
        WatchlistModel(
          id: 'default_tech_giants',
          name: 'Tech Giants',
          symbols: const ['AAPL', 'MSFT', 'GOOGL', 'NVDA', 'AMZN'],
          isDefault: true,
          createdAt: DateTime(2026, 1, 1),
        ),
        WatchlistModel(
          id: 'default_high_beta',
          name: 'High Beta',
          symbols: const ['TSLA', 'COIN', 'AMD', 'META'],
          isDefault: false,
          createdAt: DateTime(2026, 1, 1),
        ),
        WatchlistModel(
          id: 'default_dividend',
          name: 'Dividend Growth',
          symbols: const ['JNJ', 'PG', 'KO', 'PEP'],
          isDefault: false,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

  @override
  Future<List<WatchlistModel>> getWatchlists() async {
    final rawList = _storage.getJsonList(_kWatchlistsKey);
    if (rawList == null || rawList.isEmpty) {
      final seeds = _defaultSeeds;
      await _saveWatchlists(seeds);
      await setActiveWatchlistId(seeds.first.id);
      return seeds;
    }

    try {
      final watchlists = rawList.map((e) => WatchlistModel.fromJson(e)).toList();
      if (watchlists.isEmpty) {
        final seeds = _defaultSeeds;
        await _saveWatchlists(seeds);
        await setActiveWatchlistId(seeds.first.id);
        return seeds;
      }
      return watchlists;
    } catch (_) {
      final seeds = _defaultSeeds;
      await _saveWatchlists(seeds);
      await setActiveWatchlistId(seeds.first.id);
      return seeds;
    }
  }

  @override
  Future<String?> getActiveWatchlistId() async {
    final stored = _storage.getString(_kActiveWatchlistIdKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    final lists = await getWatchlists();
    return lists.isNotEmpty ? lists.first.id : null;
  }

  @override
  Future<void> setActiveWatchlistId(String id) async {
    await _storage.setString(_kActiveWatchlistIdKey, id);
  }

  @override
  Future<WatchlistModel> createWatchlist(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Watchlist name cannot be empty.');
    }

    final current = await getWatchlists();
    final newId = 'watchlist_${DateTime.now().millisecondsSinceEpoch}';
    final newWatchlist = WatchlistModel(
      id: newId,
      name: trimmedName,
      symbols: const [],
      isDefault: false,
      createdAt: DateTime.now(),
    );

    final updated = List<WatchlistModel>.from(current)..add(newWatchlist);
    await _saveWatchlists(updated);
    await setActiveWatchlistId(newId);
    return newWatchlist;
  }

  @override
  Future<WatchlistModel> renameWatchlist(String id, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Watchlist name cannot be empty.');
    }

    final current = await getWatchlists();
    final index = current.indexWhere((w) => w.id == id);
    if (index == -1) {
      throw StateError('Watchlist with id $id not found.');
    }

    final updatedModel = current[index].copyWith(name: trimmedName);
    final updatedList = List<WatchlistModel>.from(current)..[index] = updatedModel;
    await _saveWatchlists(updatedList);
    return updatedModel;
  }

  @override
  Future<void> deleteWatchlist(String id) async {
    final current = await getWatchlists();
    final updatedList = current.where((w) => w.id != id).toList();

    if (updatedList.isEmpty) {
      // Always keep at least one default watchlist
      final seeds = _defaultSeeds;
      await _saveWatchlists(seeds);
      await setActiveWatchlistId(seeds.first.id);
      return;
    }

    await _saveWatchlists(updatedList);
    final activeId = await getActiveWatchlistId();
    if (activeId == id) {
      await setActiveWatchlistId(updatedList.first.id);
    }
  }

  @override
  Future<WatchlistModel> toggleSymbolInWatchlist(
      String watchlistId, String symbol) async {
    final normalizedSymbol = symbol.trim().toUpperCase();
    final current = await getWatchlists();
    final index = current.indexWhere((w) => w.id == watchlistId);
    if (index == -1) {
      throw StateError('Watchlist with id $watchlistId not found.');
    }

    final target = current[index];
    final currentSymbols = List<String>.from(target.symbols);
    if (currentSymbols.contains(normalizedSymbol)) {
      currentSymbols.remove(normalizedSymbol);
    } else {
      currentSymbols.add(normalizedSymbol);
    }

    final updatedModel = target.copyWith(symbols: currentSymbols);
    final updatedList = List<WatchlistModel>.from(current)..[index] = updatedModel;
    await _saveWatchlists(updatedList);
    return updatedModel;
  }

  @override
  Future<List<WatchlistModel>> resetToDefaults() async {
    final seeds = _defaultSeeds;
    await _saveWatchlists(seeds);
    await setActiveWatchlistId(seeds.first.id);
    return seeds;
  }

  Future<void> _saveWatchlists(List<WatchlistModel> lists) async {
    final jsonList = lists.map((w) => w.toJson()).toList();
    await _storage.setJsonList(_kWatchlistsKey, jsonList);
  }
}
