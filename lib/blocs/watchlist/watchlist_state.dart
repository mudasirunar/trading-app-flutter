import 'package:equatable/equatable.dart';
import '../../models/watchlist_model.dart';

/// Base state class for Watchlist state management.
abstract class WatchlistState extends Equatable {
  const WatchlistState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class WatchlistsInitial extends WatchlistState {
  const WatchlistsInitial();
}

/// Loading state during storage access or data mutations.
class WatchlistsLoading extends WatchlistState {
  const WatchlistsLoading();
}

/// Successfully loaded watchlists state.
class WatchlistsLoaded extends WatchlistState {
  const WatchlistsLoaded({
    required this.watchlists,
    required this.activeWatchlistId,
  });

  final List<WatchlistModel> watchlists;
  final String activeWatchlistId;

  /// Returns the currently selected [WatchlistModel], falling back to the first available.
  WatchlistModel? get activeWatchlist {
    if (watchlists.isEmpty) return null;
    return watchlists.firstWhere(
      (w) => w.id == activeWatchlistId,
      orElse: () => watchlists.first,
    );
  }

  /// Checks if a [symbol] is saved in a specific watchlist.
  bool isSymbolInWatchlist(String watchlistId, String symbol) {
    final list = watchlists.where((w) => w.id == watchlistId).firstOrNull;
    if (list == null) return false;
    return list.symbols.contains(symbol.trim().toUpperCase());
  }

  /// Checks if a [symbol] is saved in ANY of the user's watchlists.
  bool isSymbolInAnyWatchlist(String symbol) {
    final normalized = symbol.trim().toUpperCase();
    return watchlists.any((w) => w.symbols.contains(normalized));
  }

  /// Returns all watchlists containing [symbol].
  List<WatchlistModel> watchlistsContaining(String symbol) {
    final normalized = symbol.trim().toUpperCase();
    return watchlists.where((w) => w.symbols.contains(normalized)).toList();
  }

  WatchlistsLoaded copyWith({
    List<WatchlistModel>? watchlists,
    String? activeWatchlistId,
  }) {
    return WatchlistsLoaded(
      watchlists: watchlists ?? this.watchlists,
      activeWatchlistId: activeWatchlistId ?? this.activeWatchlistId,
    );
  }

  @override
  List<Object?> get props => [watchlists, activeWatchlistId];
}

/// Failure state when storage or mutation errors occur.
class WatchlistsFailure extends WatchlistState {
  const WatchlistsFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
