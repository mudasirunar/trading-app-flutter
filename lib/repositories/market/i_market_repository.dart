import '../../models/candle_model.dart';
import '../../models/instrument_model.dart';

/// Domain contract for financial market data access, search, and live ticker subscriptions.
abstract class IMarketRepository {
  /// Reactive stream of real-time market quotes.
  Stream<List<InstrumentModel>> get marketStream;

  /// Retrieves the current snapshot of all tradable instruments.
  Future<List<InstrumentModel>> getInstruments();

  /// Retrieves an instrument by its ticker symbol (e.g., 'AAPL').
  Future<InstrumentModel?> getInstrument(String symbol);

  /// Retrieves candlestick data for charting across specific timeframes.
  Future<List<CandleModel>> getCandles(
    String symbol,
    MarketTimeframe timeframe,
  );

  /// Searches instruments matching ticker symbol or company name, optionally filtered by sector.
  Future<List<InstrumentModel>> searchInstruments(
    String query, {
    String? sector,
  });

  /// Starts the continuous quote stream.
  void startLiveFeed();

  /// Pauses the quote stream to conserve background resources.
  void stopLiveFeed();

  /// Cleans up subscriptions and resources.
  void dispose();
}
