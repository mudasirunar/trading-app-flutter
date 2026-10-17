import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/instrument_search_helper.dart';
import '../../models/candle_model.dart';
import '../../models/instrument_model.dart';
import '../../repositories/market/i_market_repository.dart';
import 'market_event.dart';
import 'market_state.dart';

/// Central reactive BLoC managing institutional market data, real-time ticks, and charting feeds.
class MarketBloc extends Bloc<MarketEvent, MarketState> {
  MarketBloc({
    required this.marketRepository,
  }) : super(const MarketInitial()) {
    on<MarketStarted>(_onMarketStarted);
    on<MarketTickReceived>(_onMarketTickReceived);
    on<MarketSearchQueryChanged>(_onMarketSearchQueryChanged);
    on<MarketTimeframeSelected>(_onMarketTimeframeSelected);
    on<MarketInstrumentSelected>(_onMarketInstrumentSelected);
    on<MarketFeedPaused>(_onMarketFeedPaused);
    on<MarketFeedResumed>(_onMarketFeedResumed);
  }

  final IMarketRepository marketRepository;
  StreamSubscription<List<InstrumentModel>>? _streamSubscription;

  Future<void> _onMarketStarted(
    MarketStarted event,
    Emitter<MarketState> emit,
  ) async {
    emit(const MarketLoading());
    try {
      final instruments = await marketRepository.getInstruments();
      final candles = await marketRepository.getCandles(
        event.defaultSymbol,
        MarketTimeframe.oneDay,
      );

      // Subscribe to real-time market stream
      await _streamSubscription?.cancel();
      _streamSubscription = marketRepository.marketStream.listen(
        (updatedInstruments) => add(MarketTickReceived(updatedInstruments)),
      );

      marketRepository.startLiveFeed();

      emit(
        MarketLoaded(
          instruments: instruments,
          searchResults: instruments,
          selectedSymbol: event.defaultSymbol,
          selectedCandles: candles,
          activeTimeframe: MarketTimeframe.oneDay,
          lastTickTimestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(MarketError('Failed to initialize market feed: ${e.toString()}'));
    }
  }

  void _onMarketTickReceived(
    MarketTickReceived event,
    Emitter<MarketState> emit,
  ) {
    if (state is! MarketLoaded) return;
    final currentState = state as MarketLoaded;

    // Filter search results against the updated tick data
    final filtered = _filterInstruments(
      event.instruments,
      currentState.searchQuery,
      currentState.selectedSector,
    );

    // Dynamic candle mutation for the currently charted instrument
    List<CandleModel> updatedCandles = currentState.selectedCandles;
    try {
      final selectedInst = event.instruments.firstWhere(
        (i) => i.symbol.toUpperCase() == currentState.selectedSymbol.toUpperCase(),
      );

      if (updatedCandles.isNotEmpty) {
        final lastIdx = updatedCandles.length - 1;
        final latestCandle = updatedCandles[lastIdx];
        final mutated = latestCandle.copyWithTick(
          selectedInst.currentPrice,
          10.0,
        );

        updatedCandles = List<CandleModel>.from(updatedCandles);
        updatedCandles[lastIdx] = mutated;
      }
    } catch (_) {
      // Instrument not in tick list, leave candles as is
    }

    emit(
      currentState.copyWith(
        instruments: event.instruments,
        searchResults: filtered,
        selectedCandles: updatedCandles,
        lastTickTimestamp: DateTime.now(),
      ),
    );
  }

  void _onMarketSearchQueryChanged(
    MarketSearchQueryChanged event,
    Emitter<MarketState> emit,
  ) {
    if (state is! MarketLoaded) return;
    final currentState = state as MarketLoaded;

    final filtered = _filterInstruments(
      currentState.instruments,
      event.query,
      event.sector,
    );

    emit(
      currentState.copyWith(
        searchQuery: event.query,
        selectedSector: event.sector,
        clearSector: event.sector == null,
        searchResults: filtered,
      ),
    );
  }

  Future<void> _onMarketTimeframeSelected(
    MarketTimeframeSelected event,
    Emitter<MarketState> emit,
  ) async {
    if (state is! MarketLoaded) return;
    final currentState = state as MarketLoaded;

    try {
      final candles = await marketRepository.getCandles(
        event.symbol,
        event.timeframe,
      );

      emit(
        currentState.copyWith(
          selectedSymbol: event.symbol,
          activeTimeframe: event.timeframe,
          selectedCandles: candles,
        ),
      );
    } catch (e) {
      emit(MarketError('Failed to load chart data for ${event.symbol}: $e'));
    }
  }

  Future<void> _onMarketInstrumentSelected(
    MarketInstrumentSelected event,
    Emitter<MarketState> emit,
  ) async {
    if (state is! MarketLoaded) return;
    final currentState = state as MarketLoaded;

    try {
      final candles = await marketRepository.getCandles(
        event.symbol,
        currentState.activeTimeframe,
      );

      emit(
        currentState.copyWith(
          selectedSymbol: event.symbol,
          selectedCandles: candles,
        ),
      );
    } catch (e) {
      emit(MarketError('Failed to focus on ${event.symbol}: $e'));
    }
  }

  void _onMarketFeedPaused(
    MarketFeedPaused event,
    Emitter<MarketState> emit,
  ) {
    if (state is! MarketLoaded) return;
    final currentState = state as MarketLoaded;

    marketRepository.stopLiveFeed();
    emit(currentState.copyWith(isFeedLive: false));
  }

  void _onMarketFeedResumed(
    MarketFeedResumed event,
    Emitter<MarketState> emit,
  ) {
    if (state is! MarketLoaded) return;
    final currentState = state as MarketLoaded;

    marketRepository.startLiveFeed();
    emit(currentState.copyWith(isFeedLive: true));
  }

  List<InstrumentModel> _filterInstruments(
    List<InstrumentModel> all,
    String query,
    String? sector,
  ) {
    return InstrumentSearchHelper.filterInstruments(
      all,
      query,
      sector: sector,
    );
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    marketRepository.stopLiveFeed();
    return super.close();
  }
}
