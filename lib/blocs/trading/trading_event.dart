import 'package:equatable/equatable.dart';
import '../../models/instrument_model.dart';
import '../../models/order_model.dart';

abstract class TradingEvent extends Equatable {
  const TradingEvent();

  @override
  List<Object?> get props => [];
}

/// Initializes trading account from repository
class TradingInitialized extends TradingEvent {
  const TradingInitialized();
}

/// User submits a new simulated order
class OrderSubmitted extends TradingEvent {
  final InstrumentModel instrument;
  final OrderSide side;
  final OrderType type;
  final double quantity;
  final double? limitPrice;
  final double? stopPrice;

  const OrderSubmitted({
    required this.instrument,
    required this.side,
    required this.type,
    required this.quantity,
    this.limitPrice,
    this.stopPrice,
  });

  @override
  List<Object?> get props => [
        instrument,
        side,
        type,
        quantity,
        limitPrice,
        stopPrice,
      ];
}

/// User cancels an active pending order
class OrderCancelled extends TradingEvent {
  final String orderId;

  const OrderCancelled({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

/// Market engine pushes a real-time price tick for an instrument, triggering order matching
class MarketTickEvaluated extends TradingEvent {
  final InstrumentModel instrument;

  const MarketTickEvaluated({required this.instrument});

  @override
  List<Object?> get props => [instrument];
}

/// Reset account to initial $100,000 virtual cash
class VirtualAccountReset extends TradingEvent {
  const VirtualAccountReset();
}
