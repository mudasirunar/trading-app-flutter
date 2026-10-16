import 'dart:async';

import '../../models/candle_model.dart';
import '../../models/instrument_model.dart';
import '../../services/market/i_market_data_source.dart';
import '../../services/market/simulated_exchange_data_source.dart';
import 'i_market_repository.dart';

/// Concrete production implementation of [IMarketRepository].
/// Decoupled from concrete data providers via [IMarketDataSource].
class MarketRepository implements IMarketRepository {
  MarketRepository({
    IMarketDataSource? dataSource,
  }) : _dataSource = dataSource ?? SimulatedExchangeDataSource() {
    _initStreamSubscription();
  }

  final IMarketDataSource _dataSource;
  StreamSubscription<List<InstrumentModel>>? _quoteSubscription;
  final StreamController<List<InstrumentModel>> _marketStreamController =
      StreamController<List<InstrumentModel>>.broadcast();

  final Map<String, InstrumentModel> _instrumentCache = {};

  void _initStreamSubscription() {
    _quoteSubscription = _dataSource.quoteStream.listen(
      (instruments) {
        for (final item in instruments) {
          _instrumentCache[item.symbol.toUpperCase()] = item;
        }
        if (!_marketStreamController.isClosed) {
          _marketStreamController.add(instruments);
        }
      },
      onError: (error, stackTrace) {
        if (!_marketStreamController.isClosed) {
          _marketStreamController.addError(error, stackTrace);
        }
      },
    );
  }

  @override
  Stream<List<InstrumentModel>> get marketStream =>
      _marketStreamController.stream;

  @override
  Future<List<InstrumentModel>> getInstruments() async {
    if (_instrumentCache.isEmpty) {
      final initial = await _dataSource.fetchInitialInstruments();
      for (final item in initial) {
        _instrumentCache[item.symbol.toUpperCase()] = item;
      }
    }
    return _instrumentCache.values.toList(growable: false);
  }

  @override
  Future<InstrumentModel?> getInstrument(String symbol) async {
    final upper = symbol.toUpperCase();
    if (_instrumentCache.containsKey(upper)) {
      return _instrumentCache[upper];
    }
    final all = await getInstruments();
    try {
      return all.firstWhere((i) => i.symbol.toUpperCase() == upper);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CandleModel>> getCandles(
    String symbol,
    MarketTimeframe timeframe,
  ) async {
    return _dataSource.fetchCandles(symbol, timeframe);
  }

  @override
  Future<List<InstrumentModel>> searchInstruments(
    String query, {
    String? sector,
  }) async {
    final all = await getInstruments();
    final cleanQuery = query.trim().toUpperCase();

    return all.where((instrument) {
      final matchesQuery = cleanQuery.isEmpty ||
          instrument.symbol.toUpperCase().contains(cleanQuery) ||
          instrument.name.toUpperCase().contains(cleanQuery);

      final matchesSector = sector == null ||
          sector.isEmpty ||
          instrument.sector.equalsIgnoreCase(sector);

      return matchesQuery && matchesSector;
    }).toList(growable: false);
  }

  @override
  void startLiveFeed() {
    _dataSource.startStream();
  }

  @override
  void stopLiveFeed() {
    _dataSource.stopStream();
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    _marketStreamController.close();
    _dataSource.dispose();
  }
}

extension _StringHelper on String {
  bool equalsIgnoreCase(String other) =>
      toLowerCase() == other.toLowerCase();
}
