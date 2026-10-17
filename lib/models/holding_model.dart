import 'package:equatable/equatable.dart';

/// Immutable Model representing an active Position / Holding in the paper trading portfolio
class HoldingModel extends Equatable {
  final String symbol;
  final double quantity;
  final double averageCost;
  final double currentPrice;

  const HoldingModel({
    required this.symbol,
    required this.quantity,
    required this.averageCost,
    required this.currentPrice,
  });

  /// Total current market valuation
  double get marketValue => quantity * currentPrice;

  /// Total cost basis invested in this position
  double get totalCost => quantity * averageCost;

  /// Unrealized profit/loss in dollars
  double get unrealizedPL => marketValue - totalCost;

  /// Unrealized profit/loss percentage
  double get unrealizedPLPercent =>
      totalCost > 0 ? (unrealizedPL / totalCost) * 100 : 0.0;

  /// Whether position is currently in profit or breaking even
  bool get isProfitable => unrealizedPL >= 0;

  HoldingModel copyWith({
    String? symbol,
    double? quantity,
    double? averageCost,
    double? currentPrice,
  }) {
    return HoldingModel(
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      averageCost: averageCost ?? this.averageCost,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'averageCost': averageCost,
      'currentPrice': currentPrice,
    };
  }

  factory HoldingModel.fromJson(Map<String, dynamic> json) {
    return HoldingModel(
      symbol: json['symbol'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      averageCost: (json['averageCost'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [symbol, quantity, averageCost, currentPrice];
}
