import 'package:equatable/equatable.dart';

/// Institutional timeframe aggregation options for financial charts.
enum MarketTimeframe {
  oneDay('1D', '1 Day', Duration(minutes: 5), 78),
  oneWeek('1W', '1 Week', Duration(hours: 1), 35),
  oneMonth('1M', '1 Month', Duration(days: 1), 30),
  threeMonths('3M', '3 Months', Duration(days: 1), 90),
  oneYear('1Y', '1 Year', Duration(days: 7), 52);

  const MarketTimeframe(
    this.code,
    this.label,
    this.candleDuration,
    this.targetCandleCount,
  );

  final String code;
  final String label;
  final Duration candleDuration;
  final int targetCandleCount;
}

/// Standard institutional OHLCV (Open, High, Low, Close, Volume) candlestick data point.
class CandleModel extends Equatable {
  const CandleModel({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  }) : assert(high >= low, 'High ($high) must be >= Low ($low)'),
       assert(high >= open && high >= close, 'High must be >= Open and Close'),
       assert(low <= open && low <= close, 'Low must be <= Open and Close');

  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  /// True if price closed higher than or equal to open (green candle).
  bool get isBullish => close >= open;

  /// True if price closed lower than open (red candle).
  bool get isBearish => close < open;

  /// Absolute price distance between Open and Close.
  double get bodyHeight => (close - open).abs();

  /// Total price range between High and Low.
  double get wickRange => high - low;

  /// Percentage price change within this candlestick bar.
  double get changePercent =>
      open > 0 ? ((close - open) / open) * 100 : 0.0;

  /// Dynamically mutates this active candle as real-time ticks stream in.
  CandleModel copyWithTick(double newPrice, double addedVolume) {
    return CandleModel(
      timestamp: timestamp,
      open: open,
      high: newPrice > high ? newPrice : high,
      low: newPrice < low ? newPrice : low,
      close: newPrice,
      volume: volume + addedVolume,
    );
  }

  CandleModel copyWith({
    DateTime? timestamp,
    double? open,
    double? high,
    double? low,
    double? close,
    double? volume,
  }) {
    return CandleModel(
      timestamp: timestamp ?? this.timestamp,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }

  factory CandleModel.fromJson(Map<String, dynamic> json) {
    return CandleModel(
      timestamp: DateTime.parse(json['timestamp'] as String),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [timestamp, open, high, low, close, volume];
}
