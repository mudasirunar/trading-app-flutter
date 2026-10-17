import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/watchlist/i_watchlist_repository.dart';
import 'watchlist_event.dart';
import 'watchlist_state.dart';

/// BLoC managing portfolio watchlists, active selections, and symbol curation.
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc({required this.repository})
      : super(const WatchlistsInitial()) {
    on<WatchlistsLoadRequested>(_onLoadRequested);
    on<WatchlistSelected>(_onSelected);
    on<WatchlistCreated>(_onCreated);
    on<WatchlistRenamed>(_onRenamed);
    on<WatchlistDeleted>(_onDeleted);
    on<WatchlistSymbolToggled>(_onSymbolToggled);
    on<WatchlistsResetRequested>(_onResetRequested);
  }

  final IWatchlistRepository repository;

  Future<void> _onLoadRequested(
    WatchlistsLoadRequested event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(const WatchlistsLoading());
    try {
      final watchlists = await repository.getWatchlists();
      final activeId = await repository.getActiveWatchlistId() ??
          (watchlists.isNotEmpty ? watchlists.first.id : '');
      emit(WatchlistsLoaded(
        watchlists: watchlists,
        activeWatchlistId: activeId,
      ));
    } catch (e) {
      emit(WatchlistsFailure(message: 'Failed to load watchlists: $e'));
    }
  }

  Future<void> _onSelected(
    WatchlistSelected event,
    Emitter<WatchlistState> emit,
  ) async {
    final currentState = state;
    if (currentState is WatchlistsLoaded) {
      await repository.setActiveWatchlistId(event.watchlistId);
      emit(currentState.copyWith(activeWatchlistId: event.watchlistId));
    }
  }

  Future<void> _onCreated(
    WatchlistCreated event,
    Emitter<WatchlistState> emit,
  ) async {
    try {
      final newWatchlist = await repository.createWatchlist(event.name);
      final all = await repository.getWatchlists();
      emit(WatchlistsLoaded(
        watchlists: all,
        activeWatchlistId: newWatchlist.id,
      ));
    } catch (e) {
      emit(WatchlistsFailure(message: 'Failed to create watchlist: $e'));
    }
  }

  Future<void> _onRenamed(
    WatchlistRenamed event,
    Emitter<WatchlistState> emit,
  ) async {
    try {
      await repository.renameWatchlist(event.id, event.newName);
      final all = await repository.getWatchlists();
      final currentState = state;
      final activeId = currentState is WatchlistsLoaded
          ? currentState.activeWatchlistId
          : all.first.id;
      emit(WatchlistsLoaded(
        watchlists: all,
        activeWatchlistId: activeId,
      ));
    } catch (e) {
      emit(WatchlistsFailure(message: 'Failed to rename watchlist: $e'));
    }
  }

  Future<void> _onDeleted(
    WatchlistDeleted event,
    Emitter<WatchlistState> emit,
  ) async {
    try {
      await repository.deleteWatchlist(event.id);
      final all = await repository.getWatchlists();
      final activeId = await repository.getActiveWatchlistId() ??
          (all.isNotEmpty ? all.first.id : '');
      emit(WatchlistsLoaded(
        watchlists: all,
        activeWatchlistId: activeId,
      ));
    } catch (e) {
      emit(WatchlistsFailure(message: 'Failed to delete watchlist: $e'));
    }
  }

  Future<void> _onSymbolToggled(
    WatchlistSymbolToggled event,
    Emitter<WatchlistState> emit,
  ) async {
    try {
      await repository.toggleSymbolInWatchlist(
        event.watchlistId,
        event.symbol,
      );
      final all = await repository.getWatchlists();
      final currentState = state;
      final activeId = currentState is WatchlistsLoaded
          ? currentState.activeWatchlistId
          : all.first.id;
      emit(WatchlistsLoaded(
        watchlists: all,
        activeWatchlistId: activeId,
      ));
    } catch (e) {
      emit(WatchlistsFailure(message: 'Failed to update watchlist: $e'));
    }
  }

  Future<void> _onResetRequested(
    WatchlistsResetRequested event,
    Emitter<WatchlistState> emit,
  ) async {
    try {
      final defaults = await repository.resetToDefaults();
      emit(WatchlistsLoaded(
        watchlists: defaults,
        activeWatchlistId: defaults.first.id,
      ));
    } catch (e) {
      emit(WatchlistsFailure(message: 'Failed to reset watchlists: $e'));
    }
  }
}
