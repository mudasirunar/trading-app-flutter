import '../../models/candle_model.dart';
import '../../models/instrument_model.dart';

/// Abstract contract for market data providers (simulated or external REST/WebSocket APIs).
abstract class IMarketDataSource {
  /// Continuous broadcast stream of updating market quotes.
  Stream<List<InstrumentModel>> get quoteStream;

  /// Fetches the initial snapshot of tradable instruments.
  Future<List<InstrumentModel>> fetchInitialInstruments();

  /// Fetches historical candlestick series for a given symbol and timeframe.
  Future<List<CandleModel>> fetchCandles(
    String symbol,
    MarketTimeframe timeframe,
  );

  /// Initiates live quote streaming.
  void startStream();

  /// Pauses live quote streaming.
  void stopStream();

  /// Releases resources, timers, and stream controllers.
  void dispose();
}
