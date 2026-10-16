import 'package:equatable/equatable.dart';

import '../../models/candle_model.dart';
import '../../models/instrument_model.dart';

abstract class MarketEvent extends Equatable {
  const MarketEvent();

  @override
  List<Object?> get props => [];
}

/// Initializes the market data catalogue and subscribes to the live quote stream.
class MarketStarted extends MarketEvent {
  const MarketStarted({this.defaultSymbol = 'AAPL'});

  final String defaultSymbol;

  @override
  List<Object?> get props => [defaultSymbol];
}

/// Internal event dispatched when a real-time stochastic market tick arrives.
class MarketTickReceived extends MarketEvent {
  const MarketTickReceived(this.instruments);

  final List<InstrumentModel> instruments;

  @override
  List<Object?> get props => [instruments];
}

/// Dispatched when the user enters search text or filters by sector.
class MarketSearchQueryChanged extends MarketEvent {
  const MarketSearchQueryChanged({
    required this.query,
    this.sector,
  });

  final String query;
  final String? sector;

  @override
  List<Object?> get props => [query, sector];
}

/// Dispatched when the user selects a financial chart timeframe (e.g., 1D, 1W, 1M, 3M, 1Y).
class MarketTimeframeSelected extends MarketEvent {
  const MarketTimeframeSelected({
    required this.symbol,
    required this.timeframe,
  });

  final String symbol;
  final MarketTimeframe timeframe;

  @override
  List<Object?> get props => [symbol, timeframe];
}

/// Dispatched when the user focuses on a specific instrument.
class MarketInstrumentSelected extends MarketEvent {
  const MarketInstrumentSelected(this.symbol);

  final String symbol;

  @override
  List<Object?> get props => [symbol];
}

/// Dispatched to pause the live stream (e.g., app moved to background).
class MarketFeedPaused extends MarketEvent {
  const MarketFeedPaused();
}

/// Dispatched to resume the live stream when app returns to foreground.
class MarketFeedResumed extends MarketEvent {
  const MarketFeedResumed();
}
