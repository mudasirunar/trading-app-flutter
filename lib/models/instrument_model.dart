import 'package:equatable/equatable.dart';

/// Directional pulse indicator representing the most recent price tick.
enum PriceDirection {
  up,
  down,
  none;

  bool get isUp => this == PriceDirection.up;
  bool get isDown => this == PriceDirection.down;
}

/// Comprehensive institutional financial equity instrument representation.
class InstrumentModel extends Equatable {
  const InstrumentModel({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.sector,
    required this.currentPrice,
    required this.openPrice,
    required this.high24h,
    required this.low24h,
    required this.previousClose,
    required this.change,
    required this.changePercentage,
    this.tickDirection = PriceDirection.none,
    required this.bidPrice,
    required this.askPrice,
    required this.spread,
    required this.bidSize,
    required this.askSize,
    required this.volume,
    required this.avgVolume,
    required this.marketCap,
    required this.peRatio,
    required this.eps,
    required this.beta,
    required this.dividendYield,
    required this.week52High,
    required this.week52Low,
    required this.sparkline,
    this.feedVenue = 'Simulated Exchange Feed • Real-Time',
    required this.lastUpdated,
  });

  final String symbol;
  final String name;
  final String exchange;
  final String sector;
  final double currentPrice;
  final double openPrice;
  final double high24h;
  final double low24h;
  final double previousClose;
  final double change;
  final double changePercentage;
  final PriceDirection tickDirection;
  final double bidPrice;
  final double askPrice;
  final double spread;
  final int bidSize;
  final int askSize;
  final double volume;
  final double avgVolume;
  final double marketCap;
  final double peRatio;
  final double eps;
  final double beta;
  final double dividendYield;
  final double week52High;
  final double week52Low;
  final List<double> sparkline;
  final String feedVenue;
  final DateTime lastUpdated;

  bool get isPositive => change >= 0;
  double get price => currentPrice;
  double get changePercent => changePercentage;

  InstrumentModel copyWith({
    String? symbol,
    String? name,
    String? exchange,
    String? sector,
    double? currentPrice,
    double? openPrice,
    double? high24h,
    double? low24h,
    double? previousClose,
    double? change,
    double? changePercentage,
    PriceDirection? tickDirection,
    double? bidPrice,
    double? askPrice,
    double? spread,
    int? bidSize,
    int? askSize,
    double? volume,
    double? avgVolume,
    double? marketCap,
    double? peRatio,
    double? eps,
    double? beta,
    double? dividendYield,
    double? week52High,
    double? week52Low,
    List<double>? sparkline,
    String? feedVenue,
    DateTime? lastUpdated,
  }) {
    return InstrumentModel(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      exchange: exchange ?? this.exchange,
      sector: sector ?? this.sector,
      currentPrice: currentPrice ?? this.currentPrice,
      openPrice: openPrice ?? this.openPrice,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      previousClose: previousClose ?? this.previousClose,
      change: change ?? this.change,
      changePercentage: changePercentage ?? this.changePercentage,
      tickDirection: tickDirection ?? this.tickDirection,
      bidPrice: bidPrice ?? this.bidPrice,
      askPrice: askPrice ?? this.askPrice,
      spread: spread ?? this.spread,
      bidSize: bidSize ?? this.bidSize,
      askSize: askSize ?? this.askSize,
      volume: volume ?? this.volume,
      avgVolume: avgVolume ?? this.avgVolume,
      marketCap: marketCap ?? this.marketCap,
      peRatio: peRatio ?? this.peRatio,
      eps: eps ?? this.eps,
      beta: beta ?? this.beta,
      dividendYield: dividendYield ?? this.dividendYield,
      week52High: week52High ?? this.week52High,
      week52Low: week52Low ?? this.week52Low,
      sparkline: sparkline ?? this.sparkline,
      feedVenue: feedVenue ?? this.feedVenue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'exchange': exchange,
      'sector': sector,
      'currentPrice': currentPrice,
      'openPrice': openPrice,
      'high24h': high24h,
      'low24h': low24h,
      'previousClose': previousClose,
      'change': change,
      'changePercentage': changePercentage,
      'tickDirection': tickDirection.name,
      'bidPrice': bidPrice,
      'askPrice': askPrice,
      'spread': spread,
      'bidSize': bidSize,
      'askSize': askSize,
      'volume': volume,
      'avgVolume': avgVolume,
      'marketCap': marketCap,
      'peRatio': peRatio,
      'eps': eps,
      'beta': beta,
      'dividendYield': dividendYield,
      'week52High': week52High,
      'week52Low': week52Low,
      'sparkline': sparkline,
      'feedVenue': feedVenue,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory InstrumentModel.fromJson(Map<String, dynamic> json) {
    return InstrumentModel(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      exchange: json['exchange'] as String? ?? 'NASDAQ',
      sector: json['sector'] as String? ?? 'Technology',
      currentPrice: (json['currentPrice'] as num).toDouble(),
      openPrice: (json['openPrice'] as num).toDouble(),
      high24h: (json['high24h'] as num).toDouble(),
      low24h: (json['low24h'] as num).toDouble(),
      previousClose: (json['previousClose'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercentage: (json['changePercentage'] as num).toDouble(),
      tickDirection: PriceDirection.values.firstWhere(
        (e) => e.name == json['tickDirection'],
        orElse: () => PriceDirection.none,
      ),
      bidPrice: (json['bidPrice'] as num).toDouble(),
      askPrice: (json['askPrice'] as num).toDouble(),
      spread: (json['spread'] as num).toDouble(),
      bidSize: (json['bidSize'] as num?)?.toInt() ?? 100,
      askSize: (json['askSize'] as num?)?.toInt() ?? 100,
      volume: (json['volume'] as num).toDouble(),
      avgVolume: (json['avgVolume'] as num).toDouble(),
      marketCap: (json['marketCap'] as num).toDouble(),
      peRatio: (json['peRatio'] as num).toDouble(),
      eps: (json['eps'] as num).toDouble(),
      beta: (json['beta'] as num).toDouble(),
      dividendYield: (json['dividendYield'] as num).toDouble(),
      week52High: (json['week52High'] as num).toDouble(),
      week52Low: (json['week52Low'] as num).toDouble(),
      sparkline: (json['sparkline'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
      feedVenue: json['feedVenue'] as String? ??
          'Simulated Exchange Feed • Real-Time',
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  @override
  List<Object?> get props => [
        symbol,
        name,
        exchange,
        sector,
        currentPrice,
        openPrice,
        high24h,
        low24h,
        previousClose,
        change,
        changePercentage,
        tickDirection,
        bidPrice,
        askPrice,
        spread,
        bidSize,
        askSize,
        volume,
        avgVolume,
        marketCap,
        peRatio,
        eps,
        beta,
        dividendYield,
        week52High,
        week52Low,
        sparkline,
        feedVenue,
        lastUpdated,
      ];
}
