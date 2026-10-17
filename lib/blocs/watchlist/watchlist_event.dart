import 'package:equatable/equatable.dart';

/// Base event class for Watchlist state management.
abstract class WatchlistEvent extends Equatable {
  const WatchlistEvent();

  @override
  List<Object?> get props => [];
}

/// Request to load all persisted watchlists or seed defaults.
class WatchlistsLoadRequested extends WatchlistEvent {
  const WatchlistsLoadRequested();
}

/// Request to switch active watchlist view.
class WatchlistSelected extends WatchlistEvent {
  const WatchlistSelected({required this.watchlistId});

  final String watchlistId;

  @override
  List<Object?> get props => [watchlistId];
}

/// Request to create a new named watchlist.
class WatchlistCreated extends WatchlistEvent {
  const WatchlistCreated({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}

/// Request to rename an existing watchlist.
class WatchlistRenamed extends WatchlistEvent {
  const WatchlistRenamed({required this.id, required this.newName});

  final String id;
  final String newName;

  @override
  List<Object?> get props => [id, newName];
}

/// Request to delete a watchlist by ID.
class WatchlistDeleted extends WatchlistEvent {
  const WatchlistDeleted({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Request to toggle (add/remove) a symbol in a specific watchlist.
class WatchlistSymbolToggled extends WatchlistEvent {
  const WatchlistSymbolToggled({
    required this.watchlistId,
    required this.symbol,
  });

  final String watchlistId;
  final String symbol;

  @override
  List<Object?> get props => [watchlistId, symbol];
}

/// Request to reset watchlists to initial institutional defaults.
class WatchlistsResetRequested extends WatchlistEvent {
  const WatchlistsResetRequested();
}
