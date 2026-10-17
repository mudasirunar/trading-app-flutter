import 'package:equatable/equatable.dart';
import '../../models/holding_model.dart';
import '../../models/order_model.dart';
import '../../models/transaction_model.dart';

abstract class TradingState extends Equatable {
  const TradingState();

  @override
  List<Object?> get props => [];
}

class TradingInitial extends TradingState {
  const TradingInitial();
}

class TradingLoading extends TradingState {
  const TradingLoading();
}

class TradingLoaded extends TradingState {
  final double virtualCash;
  final List<HoldingModel> holdings;
  final List<OrderModel> orders;
  final List<TransactionModel> transactions;
  final String? lastActionMessage;

  const TradingLoaded({
    required this.virtualCash,
    required this.holdings,
    required this.orders,
    required this.transactions,
    this.lastActionMessage,
  });

  /// Total cost basis invested across all positions
  double get totalInvested =>
      holdings.fold(0.0, (acc, item) => acc + item.totalCost);

  /// Total current market value of all positions
  double get totalHoldingsMarketValue =>
      holdings.fold(0.0, (acc, item) => acc + item.marketValue);

  /// Total account portfolio equity (Cash + Positions)
  double get totalPortfolioValue => virtualCash + totalHoldingsMarketValue;

  /// Total unrealized profit/loss across all holdings in dollars
  double get overallUnrealizedPL => totalHoldingsMarketValue - totalInvested;

  /// Total unrealized profit/loss percentage
  double get overallUnrealizedPLPercent =>
      totalInvested > 0 ? (overallUnrealizedPL / totalInvested) * 100 : 0.0;

  /// Active pending orders (Limit & Stop-loss)
  List<OrderModel> get pendingOrders =>
      orders.where((o) => o.isPending).toList();

  /// Historical filled, cancelled, or rejected orders
  List<OrderModel> get completedOrders =>
      orders.where((o) => !o.isPending).toList();

  /// Finds holding for a specific instrument symbol if owned
  HoldingModel? getHolding(String symbol) {
    try {
      return holdings.firstWhere(
        (h) => h.symbol.toUpperCase() == symbol.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Calculates available shares not already locked in pending sell orders
  double getAvailableShares(String symbol) {
    final holding = getHolding(symbol);
    if (holding == null) return 0.0;

    final lockedInPendingSells = pendingOrders
        .where((o) =>
            o.side == OrderSide.sell &&
            o.symbol.toUpperCase() == symbol.toUpperCase())
        .fold(0.0, (acc, o) => acc + o.remainingQuantity);

    return (holding.quantity - lockedInPendingSells).clamp(0.0, holding.quantity);
  }

  TradingLoaded copyWith({
    double? virtualCash,
    List<HoldingModel>? holdings,
    List<OrderModel>? orders,
    List<TransactionModel>? transactions,
    String? lastActionMessage,
  }) {
    return TradingLoaded(
      virtualCash: virtualCash ?? this.virtualCash,
      holdings: holdings ?? this.holdings,
      orders: orders ?? this.orders,
      transactions: transactions ?? this.transactions,
      lastActionMessage: lastActionMessage,
    );
  }

  @override
  List<Object?> get props => [
        virtualCash,
        holdings,
        orders,
        transactions,
        lastActionMessage,
      ];
}

class TradingActionFailure extends TradingState {
  final String errorMessage;
  final TradingLoaded? previousState;

  const TradingActionFailure({
    required this.errorMessage,
    this.previousState,
  });

  @override
  List<Object?> get props => [errorMessage, previousState];
}
