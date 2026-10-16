import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

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

  static const Map<String, List<String>> _brandAliases = {
    'GOOGL': ['google', 'alphabet', 'youtube', 'android', 'goog', 'gemini'],
    'AAPL': ['apple', 'iphone', 'ipad', 'mac', 'macbook', 'ios'],
    'MSFT': ['microsoft', 'windows', 'azure', 'xbox', 'office'],
    'NVDA': ['nvidia', 'geforce', 'gpu', 'chips', 'ai chips', 'rtx'],
    'AMZN': ['amazon', 'aws', 'prime', 'ecommerce', 'retail'],
    'META': ['meta', 'facebook', 'fb', 'instagram', 'whatsapp', 'threads', 'oculus'],
    'TSLA': ['tesla', 'musk', 'ev', 'model 3', 'model y', 'cybertruck'],
    'BRK.B': ['berkshire', 'hathaway', 'buffett', 'warren buffett'],
    'JPM': ['jpmorgan', 'chase', 'jp morgan', 'bank'],
    'V': ['visa', 'credit card', 'payments'],
    'LLY': ['eli lilly', 'lilly', 'pharma'],
    'JNJ': ['johnson', 'johnson & johnson', 'j&j'],
    'XOM': ['exxon', 'mobil', 'exxonmobil', 'oil', 'gas'],
    'WMT': ['walmart', 'supercenter'],
    'MCD': ['mcdonalds', 'mcdonald', 'burger', 'fast food'],
    'SMSN': ['samsung', 'galaxy', 'korea', 'electronics', 'smartphones', 'fold'],
    'SONY': ['sony', 'playstation', 'ps5', 'ps4', 'bravia', 'gaming', 'walkman'],
    'TTWO': ['rockstar', 'rockstar games', 'gta', 'gta 6', 'gta6', 'grand theft auto', 'red dead', 'take-two', 'ttwo', '2k'],
    'ANTH': ['anthropic', 'claude', 'claude ai', 'claude 5', 'dario amodei', 'ai'],
    'OPAI': ['openai', 'chatgpt', 'chat gpt', 'gpt', 'sam altman', 'dall-e', 'sora', 'ai'],
    'MA': ['mastercard', 'master card', 'credit card', 'payments'],
    'NFLX': ['netflix', 'streaming', 'movies', 'series'],
    'INTC': ['intel', 'core', 'chips', 'semiconductors', 'processors', 'x86'],
    'DIS': ['disney', 'walt disney', 'marvel', 'star wars', 'pixar', 'disney+'],
    'NKE': ['nike', 'shoes', 'sneakers', 'jordan', 'air jordan', 'apparel', 'just do it'],
  };

  List<InstrumentModel> _filterInstruments(
    List<InstrumentModel> all,
    String query,
    String? sector,
  ) {
    final cleanQuery = query.trim().toLowerCase();

    // 1. Sector filtering
    final sectorFiltered = all.where((instrument) {
      if (sector == null || sector.isEmpty || sector == 'All') return true;
      return instrument.sector.toLowerCase() == sector.toLowerCase();
    }).toList(growable: false);

    // If no query, return sorted alphabetically by symbol
    if (cleanQuery.isEmpty) {
      final list = List<InstrumentModel>.from(sectorFiltered);
      list.sort((a, b) => a.symbol.compareTo(b.symbol));
      return list;
    }

    // 2. Smart matching & ranking
    // Lower score = higher priority
    int calculateScore(InstrumentModel inst) {
      final sym = inst.symbol.toLowerCase();
      final name = inst.name.toLowerCase();
      final exchange = inst.exchange.toLowerCase();
      final instSector = inst.sector.toLowerCase();
      final aliases = _brandAliases[inst.symbol] ?? const [];

      // Priority 0: Exact symbol match
      if (sym == cleanQuery) return 0;

      // Priority 1: Exact brand alias match (e.g. "google" for GOOGL, "facebook" for META)
      if (aliases.contains(cleanQuery)) return 1;

      // Priority 2: Symbol starts with query or query starts with symbol
      if (sym.startsWith(cleanQuery) || cleanQuery.startsWith(sym)) return 2;

      // Priority 3: Symbol contains query
      if (sym.contains(cleanQuery)) return 3;

      // Priority 4: Company name starts with query
      if (name.startsWith(cleanQuery)) return 4;

      // Priority 5: Any word in company name starts with query
      final words = name.split(RegExp(r'[\s\-.,&]+'));
      if (words.any((w) => w.startsWith(cleanQuery))) return 5;

      // Priority 6: Any brand alias starts with query or contains query
      if (aliases.any((a) => a.startsWith(cleanQuery) || a.contains(cleanQuery) || cleanQuery.startsWith(a))) {
        return 6;
      }

      // Priority 7: Company name contains query
      if (name.contains(cleanQuery)) return 7;

      // Priority 8: Exchange matches or contains query
      if (exchange.contains(cleanQuery)) return 8;

      // Priority 9: Sector matches or contains query
      if (instSector.contains(cleanQuery)) return 9;

      // No match
      return -1;
    }

    final scored = <MapEntry<InstrumentModel, int>>[];
    for (final inst in sectorFiltered) {
      final score = calculateScore(inst);
      if (score >= 0) {
        scored.add(MapEntry(inst, score));
      }
    }

    // Sort by:
    // 1) Match Score (symbol / brand alias is top priority)
    // 2) Alphabetical order by symbol
    scored.sort((a, b) {
      final scoreCompare = a.value.compareTo(b.value);
      if (scoreCompare != 0) return scoreCompare;
      return a.key.symbol.compareTo(b.key.symbol);
    });

    return scored.map((e) => e.key).toList(growable: false);
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    marketRepository.stopLiveFeed();
    return super.close();
  }
}
