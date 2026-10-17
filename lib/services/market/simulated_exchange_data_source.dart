import 'dart:async';
import 'dart:math' as math;

import '../../models/candle_model.dart';
import '../../models/instrument_model.dart';
import 'i_market_data_source.dart';

/// Production-grade stochastic market data engine utilizing Geometric Brownian Motion.
/// Generates 24/7 continuous tick streaming, dynamic candle mutations, and multi-timeframe OHLCV bars.
class SimulatedExchangeDataSource implements IMarketDataSource {
  SimulatedExchangeDataSource({
    this.tickInterval = const Duration(milliseconds: 1500),
    int? randomSeed,
  }) : _random = randomSeed != null ? math.Random(randomSeed) : math.Random();

  final Duration tickInterval;
  final math.Random _random;

  Timer? _tickTimer;
  StreamController<List<InstrumentModel>>? _streamController;

  // In-memory state of active instruments
  final Map<String, InstrumentModel> _instrumentCatalog = {};

  // In-memory cache for historical candles per symbol and timeframe
  final Map<String, Map<MarketTimeframe, List<CandleModel>>> _candleCache = {};

  @override
  Stream<List<InstrumentModel>> get quoteStream {
    _streamController ??=
        StreamController<List<InstrumentModel>>.broadcast();
    return _streamController!.stream;
  }

  @override
  Future<List<InstrumentModel>> fetchInitialInstruments() async {
    if (_instrumentCatalog.isEmpty) {
      _seedCatalog();
    }
    return _instrumentCatalog.values.toList(growable: false);
  }

  @override
  Future<List<CandleModel>> fetchCandles(
    String symbol,
    MarketTimeframe timeframe,
  ) async {
    if (_instrumentCatalog.isEmpty) {
      _seedCatalog();
    }

    final instrument = _instrumentCatalog[symbol] ??
        _instrumentCatalog.values.first;

    _candleCache.putIfAbsent(symbol, () => {});
    if (!_candleCache[symbol]!.containsKey(timeframe)) {
      _candleCache[symbol]![timeframe] = _generateHistoricalCandles(
        instrument: instrument,
        timeframe: timeframe,
      );
    }

    return List<CandleModel>.from(_candleCache[symbol]![timeframe]!);
  }

  @override
  void startStream() {
    if (_instrumentCatalog.isEmpty) {
      _seedCatalog();
    }

    if (_tickTimer != null && _tickTimer!.isActive) return;

    _tickTimer = Timer.periodic(tickInterval, (_) => _processTick());
  }

  @override
  void stopStream() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  @override
  void dispose() {
    stopStream();
    _streamController?.close();
    _streamController = null;
  }

  // ===========================================================================
  // STOCHASTIC TICK ENGINE (Geometric Brownian Motion)
  // ===========================================================================

  void _processTick() {
    if (_instrumentCatalog.isEmpty) return;

    final updatedList = <InstrumentModel>[];
    final now = DateTime.now();

    for (final instrument in _instrumentCatalog.values) {
      final updated = _computeNextTick(instrument, now);
      _instrumentCatalog[instrument.symbol] = updated;
      updatedList.add(updated);

      // Mutate the active in-flight candle if currently loaded in cache
      _mutateActiveCandle(updated);
    }

    if (_streamController != null && !_streamController!.isClosed) {
      _streamController!.add(updatedList);
    }
  }

  InstrumentModel _computeNextTick(InstrumentModel current, DateTime now) {
    final volatility = _getSectorVolatility(current.sector);

    // Box-Muller Gaussian standard normal variate Z ~ N(0, 1)
    final double z = _boxMullerGaussian();

    // Realistic active trading session micro-tick simulation:
    // Prices fluctuate smoothly up and down with two-sided Brownian noise.
    final double randomNoise = (_random.nextDouble() - 0.495) * 0.0016;
    final double microShock = (z * volatility * 0.0022) + randomNoise;

    // Gentle mean-reverting drift toward openPrice to prevent runaway divergence
    final double meanReversion =
        0.015 * ((current.openPrice - current.currentPrice) / current.openPrice);

    double newPrice = current.currentPrice * (1.0 + microShock + meanReversion);

    // Financial terminal rounding to 2 decimal places
    newPrice = double.parse(newPrice.toStringAsFixed(2));
    if (newPrice <= 0.01) newPrice = 0.01;

    // Price direction determination
    final PriceDirection direction;
    if (newPrice > current.currentPrice) {
      direction = PriceDirection.up;
    } else if (newPrice < current.currentPrice) {
      direction = PriceDirection.down;
    } else {
      direction = PriceDirection.none;
    }

    // 24h High and Low updates
    final newHigh = newPrice > current.high24h ? newPrice : current.high24h;
    final newLow = newPrice < current.low24h ? newPrice : current.low24h;

    // Change metrics relative to previousClose
    final change = double.parse((newPrice - current.previousClose).toStringAsFixed(2));
    final changePercentage = current.previousClose > 0
        ? double.parse(((change / current.previousClose) * 100).toStringAsFixed(2))
        : 0.0;

    // Institutional Bid/Ask spread modeling (0.02% - 0.04% of price)
    final spreadRate = 0.0002 + (_random.nextDouble() * 0.0002);
    final spread = double.parse(math.max(0.01, newPrice * spreadRate).toStringAsFixed(2));
    final halfSpread = spread / 2.0;

    final bidPrice = double.parse(math.max(0.01, newPrice - halfSpread).toStringAsFixed(2));
    final askPrice = double.parse((newPrice + halfSpread).toStringAsFixed(2));

    // Dynamic depth block sizes
    final bidSize = 100 + (_random.nextInt(40) * 100);
    final askSize = 100 + (_random.nextInt(40) * 100);

    // Incremental trading volume
    final addedVolume = 50.0 + _random.nextInt(250).toDouble();
    final newVolume = current.volume + addedVolume;

    // Dynamic sparkline update (sliding window of 25 points)
    final updatedSparkline = List<double>.from(current.sparkline);
    if (updatedSparkline.isNotEmpty) {
      updatedSparkline.add(newPrice);
      if (updatedSparkline.length > 25) {
        updatedSparkline.removeAt(0);
      }
    }

    return current.copyWith(
      currentPrice: newPrice,
      high24h: newHigh,
      low24h: newLow,
      change: change,
      changePercentage: changePercentage,
      tickDirection: direction,
      bidPrice: bidPrice,
      askPrice: askPrice,
      spread: spread,
      bidSize: bidSize,
      askSize: askSize,
      volume: newVolume,
      sparkline: updatedSparkline,
      lastUpdated: now,
    );
  }

  void _mutateActiveCandle(InstrumentModel instrument) {
    final cachedTimeframes = _candleCache[instrument.symbol];
    if (cachedTimeframes == null) return;

    for (final timeframe in cachedTimeframes.keys) {
      final candles = cachedTimeframes[timeframe];
      if (candles == null || candles.isEmpty) continue;

      final lastIndex = candles.length - 1;
      final activeCandle = candles[lastIndex];

      // Mutate active candle with the latest price tick
      candles[lastIndex] = activeCandle.copyWithTick(
        instrument.currentPrice,
        15.0 + _random.nextInt(40).toDouble(),
      );
    }
  }

  double _boxMullerGaussian() {
    double u1 = _random.nextDouble();
    while (u1 <= 1e-15) {
      u1 = _random.nextDouble();
    }
    final double u2 = _random.nextDouble();
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
  }

  double _getSectorVolatility(String sector) {
    switch (sector.toLowerCase()) {
      case 'semiconductors':
      case 'automotive':
        return 0.35;
      case 'technology':
      case 'consumer cyclical':
        return 0.24;
      case 'financial services':
      case 'healthcare':
        return 0.16;
      case 'energy':
      case 'consumer staples':
      default:
        return 0.14;
    }
  }

  // ===========================================================================
  // DETERMINISTIC HISTORICAL CANDLESTICK SYNTHESIS
  // ===========================================================================

  List<CandleModel> _generateHistoricalCandles({
    required InstrumentModel instrument,
    required MarketTimeframe timeframe,
  }) {
    final candles = <CandleModel>[];
    final count = timeframe.targetCandleCount;
    final duration = timeframe.candleDuration;
    final now = DateTime.now();

    // Deterministic random generator for visual consistency
    final seed = instrument.symbol.hashCode ^ timeframe.index;
    final candleRand = math.Random(seed);

    double currentPrice = instrument.previousClose > 0
        ? instrument.previousClose
        : instrument.currentPrice * 0.98;

    final volatility = _getSectorVolatility(instrument.sector);
    final dt = duration.inMinutes / (252.0 * 6.5 * 60.0);

    for (int i = count - 1; i >= 0; i--) {
      final candleTime = now.subtract(duration * i);

      final open = currentPrice;

      // Gaussian step for close
      double u1 = candleRand.nextDouble();
      while (u1 <= 1e-15) {
        u1 = candleRand.nextDouble();
      }
      final double u2 = candleRand.nextDouble();
      final z = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);

      final exponent = -0.5 * volatility * volatility * dt +
          volatility * math.sqrt(dt) * z;
      double close = open * math.exp(exponent);

      // If it's the very latest candle, anchor close to current live price
      if (i == 0) {
        close = instrument.currentPrice;
      }

      close = double.parse(close.toStringAsFixed(2));
      if (close <= 0.01) close = 0.01;

      // Ensure High and Low envelope Open and Close strictly
      final upperBody = math.max(open, close);
      final lowerBody = math.min(open, close);

      final highWick = upperBody * (candleRand.nextDouble() * 0.006);
      final lowWick = lowerBody * (candleRand.nextDouble() * 0.006);

      final high = double.parse((upperBody + highWick).toStringAsFixed(2));
      final low = double.parse(math.max(0.01, lowerBody - lowWick).toStringAsFixed(2));

      // Intraday U-curve volume profile
      final double progress = (count - i) / count.toDouble();
      final double uShapeFactor = 4.0 * math.pow(progress - 0.5, 2);
      final baseVolume = (instrument.avgVolume / count) * 0.6;
      final volume = double.parse(
        (baseVolume * (1.0 + uShapeFactor) * (0.8 + candleRand.nextDouble() * 0.4))
            .toStringAsFixed(0),
      );

      candles.add(
        CandleModel(
          timestamp: candleTime,
          open: open,
          high: math.max(high, upperBody),
          low: math.min(low, lowerBody),
          close: close,
          volume: volume,
        ),
      );

      currentPrice = close;
    }

    return candles;
  }

  // ===========================================================================
  // INITIAL ASSET CATALOGUE (15 Premier Institutional Equities)
  // ===========================================================================

  void _seedCatalog() {
    _instrumentCatalog.clear();
    final now = DateTime.now();

    final seedDefinitions = [
      _SeedDefinition(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        exchange: 'NASDAQ',
        sector: 'Technology',
        basePrice: 232.50,
        peRatio: 34.2,
        eps: 6.80,
        beta: 1.08,
        dividendYield: 0.44,
        marketCap: 3560000000000, // $3.56T
        avgVolume: 48000000,
        week52High: 237.23,
        week52Low: 164.08,
      ),
      _SeedDefinition(
        symbol: 'MSFT',
        name: 'Microsoft Corp.',
        exchange: 'NASDAQ',
        sector: 'Technology',
        basePrice: 428.00,
        peRatio: 36.4,
        eps: 11.75,
        beta: 0.92,
        dividendYield: 0.70,
        marketCap: 3180000000000, // $3.18T
        avgVolume: 21000000,
        week52High: 468.35,
        week52Low: 366.50,
      ),
      _SeedDefinition(
        symbol: 'NVDA',
        name: 'NVIDIA Corporation',
        exchange: 'NASDAQ',
        sector: 'Semiconductors',
        basePrice: 138.25,
        peRatio: 58.6,
        eps: 2.36,
        beta: 1.68,
        dividendYield: 0.03,
        marketCap: 3390000000000, // $3.39T
        avgVolume: 56000000,
        week52High: 140.76,
        week52Low: 39.23,
      ),
      _SeedDefinition(
        symbol: 'GOOGL',
        name: 'Alphabet Inc.',
        exchange: 'NASDAQ',
        sector: 'Technology',
        basePrice: 164.80,
        peRatio: 23.8,
        eps: 6.92,
        beta: 1.04,
        dividendYield: 0.48,
        marketCap: 2040000000000, // $2.04T
        avgVolume: 24000000,
        week52High: 191.75,
        week52Low: 120.21,
      ),
      _SeedDefinition(
        symbol: 'AMZN',
        name: 'Amazon.com Inc.',
        exchange: 'NASDAQ',
        sector: 'Consumer Cyclical',
        basePrice: 186.40,
        peRatio: 43.1,
        eps: 4.32,
        beta: 1.15,
        dividendYield: 0.00,
        marketCap: 1940000000000, // $1.94T
        avgVolume: 38000000,
        week52High: 201.20,
        week52Low: 118.35,
      ),
      _SeedDefinition(
        symbol: 'META',
        name: 'Meta Platforms Inc.',
        exchange: 'NASDAQ',
        sector: 'Technology',
        basePrice: 582.00,
        peRatio: 28.5,
        eps: 20.42,
        beta: 1.22,
        dividendYield: 0.34,
        marketCap: 1470000000000, // $1.47T
        avgVolume: 14000000,
        week52High: 602.95,
        week52Low: 279.40,
      ),
      _SeedDefinition(
        symbol: 'TSLA',
        name: 'Tesla Inc.',
        exchange: 'NASDAQ',
        sector: 'Automotive',
        basePrice: 218.90,
        peRatio: 62.4,
        eps: 3.51,
        beta: 2.30,
        dividendYield: 0.00,
        marketCap: 698000000000, // $698B
        avgVolume: 72000000,
        week52High: 271.00,
        week52Low: 138.80,
      ),
      _SeedDefinition(
        symbol: 'BRK.B',
        name: 'Berkshire Hathaway Inc.',
        exchange: 'NYSE',
        sector: 'Financial Services',
        basePrice: 452.10,
        peRatio: 21.0,
        eps: 21.53,
        beta: 0.88,
        dividendYield: 0.00,
        marketCap: 994000000000, // $994B
        avgVolume: 3200000,
        week52High: 484.00,
        week52Low: 341.20,
      ),
      _SeedDefinition(
        symbol: 'JPM',
        name: 'JPMorgan Chase & Co.',
        exchange: 'NYSE',
        sector: 'Financial Services',
        basePrice: 221.40,
        peRatio: 12.3,
        eps: 18.00,
        beta: 1.10,
        dividendYield: 2.08,
        marketCap: 632000000000, // $632B
        avgVolume: 9400000,
        week52High: 225.48,
        week52Low: 140.40,
      ),
      _SeedDefinition(
        symbol: 'V',
        name: 'Visa Inc.',
        exchange: 'NYSE',
        sector: 'Financial Services',
        basePrice: 280.60,
        peRatio: 30.1,
        eps: 9.32,
        beta: 0.95,
        dividendYield: 0.74,
        marketCap: 568000000000, // $568B
        avgVolume: 6100000,
        week52High: 290.96,
        week52Low: 228.00,
      ),
      _SeedDefinition(
        symbol: 'LLY',
        name: 'Eli Lilly and Company',
        exchange: 'NYSE',
        sector: 'Healthcare',
        basePrice: 912.00,
        peRatio: 114.0,
        eps: 8.00,
        beta: 0.65,
        dividendYield: 0.57,
        marketCap: 866000000000, // $866B
        avgVolume: 3100000,
        week52High: 972.53,
        week52Low: 540.20,
      ),
      _SeedDefinition(
        symbol: 'JNJ',
        name: 'Johnson & Johnson',
        exchange: 'NYSE',
        sector: 'Healthcare',
        basePrice: 161.30,
        peRatio: 24.2,
        eps: 6.66,
        beta: 0.54,
        dividendYield: 3.07,
        marketCap: 388000000000, // $388B
        avgVolume: 6800000,
        week52High: 168.96,
        week52Low: 143.16,
      ),
      _SeedDefinition(
        symbol: 'XOM',
        name: 'Exxon Mobil Corp.',
        exchange: 'NYSE',
        sector: 'Energy',
        basePrice: 124.50,
        peRatio: 14.6,
        eps: 8.53,
        beta: 0.98,
        dividendYield: 3.05,
        marketCap: 494000000000, // $494B
        avgVolume: 16500000,
        week52High: 126.34,
        week52Low: 95.77,
      ),
      _SeedDefinition(
        symbol: 'WMT',
        name: 'Walmart Inc.',
        exchange: 'NYSE',
        sector: 'Consumer Staples',
        basePrice: 80.40,
        peRatio: 33.2,
        eps: 2.42,
        beta: 0.52,
        dividendYield: 1.03,
        marketCap: 646000000000, // $646B
        avgVolume: 22000000,
        week52High: 81.33,
        week52Low: 49.85,
      ),
      _SeedDefinition(
        symbol: 'MCD',
        name: 'McDonald\'s Corp.',
        exchange: 'NYSE',
        sector: 'Consumer Cyclical',
        basePrice: 298.70,
        peRatio: 25.8,
        eps: 11.58,
        beta: 0.68,
        dividendYield: 2.37,
        marketCap: 214000000000, // $214B
        avgVolume: 2700000,
        week52High: 317.90,
        week52Low: 243.53,
      ),
      _SeedDefinition(
        symbol: 'SMSN',
        name: 'Samsung Electronics Co., Ltd.',
        exchange: 'NASDAQ',
        sector: 'Technology',
        basePrice: 48.20,
        peRatio: 13.4,
        eps: 3.60,
        beta: 1.18,
        dividendYield: 2.64,
        marketCap: 340000000000, // $340B
        avgVolume: 12500000,
        week52High: 62.50,
        week52Low: 42.10,
      ),
      _SeedDefinition(
        symbol: 'SONY',
        name: 'Sony Group Corp.',
        exchange: 'NYSE',
        sector: 'Technology',
        basePrice: 94.50,
        peRatio: 17.2,
        eps: 5.49,
        beta: 0.92,
        dividendYield: 0.65,
        marketCap: 118000000000, // $118B
        avgVolume: 3800000,
        week52High: 101.40,
        week52Low: 78.20,
      ),
      _SeedDefinition(
        symbol: 'TTWO',
        name: 'Take-Two Interactive (Rockstar Games)',
        exchange: 'NASDAQ',
        sector: 'Technology',
        basePrice: 158.40,
        peRatio: 34.5,
        eps: 4.59,
        beta: 0.85,
        dividendYield: 0.00,
        marketCap: 27500000000, // $27.5B
        avgVolume: 2100000,
        week52High: 172.50,
        week52Low: 132.80,
      ),
      _SeedDefinition(
        symbol: 'ANTH',
        name: 'Anthropic PBC (Claude AI)',
        exchange: 'NASDAQ',
        sector: 'Technology',
        basePrice: 125.00,
        peRatio: 48.0,
        eps: 2.60,
        beta: 1.65,
        dividendYield: 0.00,
        marketCap: 45000000000, // $45B
        avgVolume: 8500000,
        week52High: 148.00,
        week52Low: 65.00,
      ),
      _SeedDefinition(
        symbol: 'OPAI',
        name: 'OpenAI Inc. (ChatGPT)',
        exchange: 'NASDAQ',
        sector: 'Technology',
        basePrice: 195.00,
        peRatio: 65.0,
        eps: 3.00,
        beta: 1.80,
        dividendYield: 0.00,
        marketCap: 157000000000, // $157B
        avgVolume: 16000000,
        week52High: 220.00,
        week52Low: 88.00,
      ),
      _SeedDefinition(
        symbol: 'MA',
        name: 'Mastercard Inc.',
        exchange: 'NYSE',
        sector: 'Financial Services',
        basePrice: 512.40,
        peRatio: 37.2,
        eps: 13.77,
        beta: 0.98,
        dividendYield: 0.52,
        marketCap: 475000000000, // $475B
        avgVolume: 2900000,
        week52High: 535.00,
        week52Low: 385.00,
      ),
      _SeedDefinition(
        symbol: 'NFLX',
        name: 'Netflix Inc.',
        exchange: 'NASDAQ',
        sector: 'Technology',
        basePrice: 724.80,
        peRatio: 42.8,
        eps: 16.93,
        beta: 1.28,
        dividendYield: 0.00,
        marketCap: 310000000000, // $310B
        avgVolume: 4200000,
        week52High: 735.00,
        week52Low: 375.00,
      ),
      _SeedDefinition(
        symbol: 'INTC',
        name: 'Intel Corp.',
        exchange: 'NASDAQ',
        sector: 'Semiconductors',
        basePrice: 23.40,
        peRatio: 22.5,
        eps: 1.04,
        beta: 1.15,
        dividendYield: 2.14,
        marketCap: 99800000000, // $99.8B
        avgVolume: 48000000,
        week52High: 51.28,
        week52Low: 18.80,
      ),
      _SeedDefinition(
        symbol: 'DIS',
        name: 'The Walt Disney Company',
        exchange: 'NYSE',
        sector: 'Consumer Cyclical',
        basePrice: 96.80,
        peRatio: 19.6,
        eps: 4.94,
        beta: 1.38,
        dividendYield: 0.93,
        marketCap: 176000000000, // $176B
        avgVolume: 9800000,
        week52High: 123.74,
        week52Low: 83.91,
      ),
      _SeedDefinition(
        symbol: 'NKE',
        name: 'NIKE, Inc.',
        exchange: 'NYSE',
        sector: 'Consumer Cyclical',
        basePrice: 84.20,
        peRatio: 23.1,
        eps: 3.64,
        beta: 1.12,
        dividendYield: 1.76,
        marketCap: 126000000000, // $126B
        avgVolume: 10500000,
        week52High: 123.39,
        week52Low: 70.75,
      ),
      _SeedDefinition(
        symbol: 'PG',
        name: 'Procter & Gamble Co.',
        exchange: 'NYSE',
        sector: 'Consumer Staples',
        basePrice: 168.50,
        peRatio: 26.4,
        eps: 6.59,
        beta: 0.58,
        dividendYield: 2.38,
        marketCap: 395000000000, // $395B
        avgVolume: 6500000,
        week52High: 177.94,
        week52Low: 143.22,
      ),
      _SeedDefinition(
        symbol: 'KO',
        name: 'The Coca-Cola Company',
        exchange: 'NYSE',
        sector: 'Consumer Staples',
        basePrice: 68.20,
        peRatio: 27.1,
        eps: 2.68,
        beta: 0.55,
        dividendYield: 2.85,
        marketCap: 294000000000, // $294B
        avgVolume: 13200000,
        week52High: 73.53,
        week52Low: 51.55,
      ),
      _SeedDefinition(
        symbol: 'PEP',
        name: 'PepsiCo, Inc.',
        exchange: 'NASDAQ',
        sector: 'Consumer Staples',
        basePrice: 172.40,
        peRatio: 25.8,
        eps: 7.20,
        beta: 0.54,
        dividendYield: 3.12,
        marketCap: 236000000000, // $236B
        avgVolume: 5100000,
        week52High: 183.25,
        week52Low: 155.83,
      ),
      _SeedDefinition(
        symbol: 'COIN',
        name: 'Coinbase Global, Inc.',
        exchange: 'NASDAQ',
        sector: 'Financial Services',
        basePrice: 215.30,
        peRatio: 42.0,
        eps: 5.12,
        beta: 2.85,
        dividendYield: 0.00,
        marketCap: 53000000000, // $53B
        avgVolume: 11500000,
        week52High: 283.48,
        week52Low: 70.12,
      ),
      _SeedDefinition(
        symbol: 'AMD',
        name: 'Advanced Micro Devices, Inc.',
        exchange: 'NASDAQ',
        sector: 'Semiconductors',
        basePrice: 156.20,
        peRatio: 118.0,
        eps: 1.32,
        beta: 1.72,
        dividendYield: 0.00,
        marketCap: 252000000000, // $252B
        avgVolume: 44000000,
        week52High: 227.30,
        week52Low: 94.04,
      ),
    ];

    // Realistic market day distribution (healthy mix of gainers and losers)
    final dayReturnPcts = <String, double>{
      'AAPL': -1.24,
      'MSFT': 1.15,
      'NVDA': 2.85,
      'GOOGL': -0.72,
      'AMZN': 1.48,
      'META': 1.92,
      'TSLA': -2.35,
      'BRK.B': 0.35,
      'JPM': -1.10,
      'V': 0.62,
      'LLY': 2.10,
      'JNJ': -0.85,
      'XOM': -1.45,
      'WMT': -0.42,
      'MCD': 0.78,
      'SMSN': 0.85,
      'SONY': -0.65,
      'TTWO': 3.12,
      'ANTH': 4.25,
      'OPAI': 3.80,
      'MA': 0.45,
      'NFLX': 1.68,
      'INTC': -1.85,
      'DIS': -0.92,
      'NKE': -1.35,
      'PG': 0.42,
      'KO': 0.65,
      'PEP': -0.38,
      'COIN': 4.15,
      'AMD': 2.30,
    };

    for (final def in seedDefinitions) {
      // Calculate realistic baseline metrics
      final baselinePct = dayReturnPcts[def.symbol] ?? ((_random.nextDouble() * 4.0) - 2.0);
      final previousClose = def.basePrice / (1.0 + (baselinePct / 100.0));
      final roundedPreviousClose = double.parse(previousClose.toStringAsFixed(2));
      final change = double.parse((def.basePrice - roundedPreviousClose).toStringAsFixed(2));
      final changePercent = double.parse(baselinePct.toStringAsFixed(2));

      final spread = double.parse(math.max(0.01, def.basePrice * 0.0003).toStringAsFixed(2));
      final bid = double.parse((def.basePrice - spread / 2).toStringAsFixed(2));
      final ask = double.parse((def.basePrice + spread / 2).toStringAsFixed(2));

      // Generate seed sparkline of 20 points following the trend
      final sparkline = <double>[];
      double p = roundedPreviousClose;
      final step = (def.basePrice - roundedPreviousClose) / 19.0;
      for (int s = 0; s < 20; s++) {
        p += step + ((_random.nextDouble() - 0.5) * (def.basePrice * 0.0025));
        sparkline.add(double.parse(p.toStringAsFixed(2)));
      }

      _instrumentCatalog[def.symbol] = InstrumentModel(
        symbol: def.symbol,
        name: def.name,
        exchange: def.exchange,
        sector: def.sector,
        currentPrice: def.basePrice,
        openPrice: roundedPreviousClose,
        high24h: double.parse((def.basePrice * 1.015).toStringAsFixed(2)),
        low24h: double.parse((def.basePrice * 0.985).toStringAsFixed(2)),
        previousClose: roundedPreviousClose,
        change: change,
        changePercentage: changePercent,
        tickDirection: PriceDirection.none,
        bidPrice: bid,
        askPrice: ask,
        spread: spread,
        bidSize: 500,
        askSize: 500,
        volume: (def.avgVolume * 0.4).roundToDouble(),
        avgVolume: def.avgVolume,
        marketCap: def.marketCap,
        peRatio: def.peRatio,
        eps: def.eps,
        beta: def.beta,
        dividendYield: def.dividendYield,
        week52High: def.week52High,
        week52Low: def.week52Low,
        sparkline: sparkline,
        feedVenue: 'Simulated Exchange Feed • Real-Time',
        lastUpdated: now,
      );
    }
  }
}

class _SeedDefinition {
  const _SeedDefinition({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.sector,
    required this.basePrice,
    required this.peRatio,
    required this.eps,
    required this.beta,
    required this.dividendYield,
    required this.marketCap,
    required this.avgVolume,
    required this.week52High,
    required this.week52Low,
  });

  final String symbol;
  final String name;
  final String exchange;
  final String sector;
  final double basePrice;
  final double peRatio;
  final double eps;
  final double beta;
  final double dividendYield;
  final double marketCap;
  final double avgVolume;
  final double week52High;
  final double week52Low;
}
