import '../../models/watchlist_model.dart';

/// Domain contract defining portfolio watchlist retrieval, persistence, and mutations.
abstract class IWatchlistRepository {
  /// Fetches all persisted watchlists, or seeds and returns default lists on first launch.
  Future<List<WatchlistModel>> getWatchlists();

  /// Gets the currently active watchlist ID, if any.
  Future<String?> getActiveWatchlistId();

  /// Sets the currently active watchlist ID.
  Future<void> setActiveWatchlistId(String id);

  /// Creates a new watchlist with the given [name].
  Future<WatchlistModel> createWatchlist(String name);

  /// Renames an existing watchlist.
  Future<WatchlistModel> renameWatchlist(String id, String newName);

  /// Deletes a watchlist by [id].
  Future<void> deleteWatchlist(String id);

  /// Adds or removes a [symbol] from the watchlist identified by [watchlistId].
  Future<WatchlistModel> toggleSymbolInWatchlist(String watchlistId, String symbol);

  /// Restores initial institutional default watchlists.
  Future<List<WatchlistModel>> resetToDefaults();
}
