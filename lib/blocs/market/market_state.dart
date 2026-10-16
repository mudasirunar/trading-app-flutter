import 'package:equatable/equatable.dart';

import '../../models/candle_model.dart';
import '../../models/instrument_model.dart';

abstract class MarketState extends Equatable {
  const MarketState();

  @override
  List<Object?> get props => [];
}

class MarketInitial extends MarketState {
  const MarketInitial();
}

class MarketLoading extends MarketState {
  const MarketLoading();
}

class MarketLoaded extends MarketState {
  const MarketLoaded({
    required this.instruments,
    required this.searchResults,
    required this.selectedSymbol,
    required this.selectedCandles,
    this.activeTimeframe = MarketTimeframe.oneDay,
    this.searchQuery = '',
    this.selectedSector,
    this.feedVenue = 'Simulated Exchange Feed • Real-Time',
    this.isFeedLive = true,
    required this.lastTickTimestamp,
  });

  final List<InstrumentModel> instruments;
  final List<InstrumentModel> searchResults;
  final String selectedSymbol;
  final List<CandleModel> selectedCandles;
  final MarketTimeframe activeTimeframe;
  final String searchQuery;
  final String? selectedSector;
  final String feedVenue;
  final bool isFeedLive;
  final DateTime lastTickTimestamp;

  InstrumentModel? get selectedInstrument {
    try {
      return instruments.firstWhere(
        (i) => i.symbol.toUpperCase() == selectedSymbol.toUpperCase(),
      );
    } catch (_) {
      return instruments.isNotEmpty ? instruments.first : null;
    }
  }

  MarketLoaded copyWith({
    List<InstrumentModel>? instruments,
    List<InstrumentModel>? searchResults,
    String? selectedSymbol,
    List<CandleModel>? selectedCandles,
    MarketTimeframe? activeTimeframe,
    String? searchQuery,
    String? selectedSector,
    bool clearSector = false,
    String? feedVenue,
    bool? isFeedLive,
    DateTime? lastTickTimestamp,
  }) {
    return MarketLoaded(
      instruments: instruments ?? this.instruments,
      searchResults: searchResults ?? this.searchResults,
      selectedSymbol: selectedSymbol ?? this.selectedSymbol,
      selectedCandles: selectedCandles ?? this.selectedCandles,
      activeTimeframe: activeTimeframe ?? this.activeTimeframe,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSector: clearSector ? null : (selectedSector ?? this.selectedSector),
      feedVenue: feedVenue ?? this.feedVenue,
      isFeedLive: isFeedLive ?? this.isFeedLive,
      lastTickTimestamp: lastTickTimestamp ?? this.lastTickTimestamp,
    );
  }

  @override
  List<Object?> get props => [
        instruments,
        searchResults,
        selectedSymbol,
        selectedCandles,
        activeTimeframe,
        searchQuery,
        selectedSector,
        feedVenue,
        isFeedLive,
        lastTickTimestamp,
      ];
}

class MarketError extends MarketState {
  const MarketError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
