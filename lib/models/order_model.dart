import 'package:equatable/equatable.dart';

/// Trading transaction side (Buy vs Sell)
enum OrderSide {
  buy,
  sell;

  String get label => this == OrderSide.buy ? 'Buy' : 'Sell';

  static OrderSide fromString(String val) {
    return OrderSide.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => OrderSide.buy,
    );
  }
}

/// Execution order type
enum OrderType {
  market,
  limit,
  stopLoss;

  String get label {
    switch (this) {
      case OrderType.market:
        return 'Market';
      case OrderType.limit:
        return 'Limit';
      case OrderType.stopLoss:
        return 'Stop-Loss';
    }
  }

  static OrderType fromString(String val) {
    return OrderType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => OrderType.market,
    );
  }
}

/// Lifecycle status of an order
enum OrderStatus {
  pending,
  partiallyFilled,
  filled,
  cancelled,
  rejected;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.partiallyFilled:
        return 'Partially Filled';
      case OrderStatus.filled:
        return 'Filled';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  static OrderStatus fromString(String val) {
    return OrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Immutable Model representing a Paper Trading Order
class OrderModel extends Equatable {
  final String id;
  final String symbol;
  final OrderSide side;
  final OrderType type;
  final double quantity;
  final double filledQuantity;
  final double? limitPrice;
  final double? stopPrice;
  final double? executionPrice;
  final double fees;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? executedAt;

  const OrderModel({
    required this.id,
    required this.symbol,
    required this.side,
    required this.type,
    required this.quantity,
    this.filledQuantity = 0.0,
    double? price,
    double? limitPrice,
    this.stopPrice,
    double? executedPrice,
    double? executionPrice,
    double? fee,
    double? fees,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.executedAt,
  })  : limitPrice = limitPrice ?? price,
        executionPrice = executionPrice ?? executedPrice,
        fees = fees ?? fee ?? 0.0;

  /// Convenience aliases for backward compatibility and test ergonomics
  double? get price => limitPrice ?? stopPrice;
  double? get executedPrice => executionPrice;
  double get fee => fees;

  /// Whether the order is currently active and awaiting execution
  bool get isPending =>
      status == OrderStatus.pending || status == OrderStatus.partiallyFilled;

  /// Whether the order has completely executed
  bool get isFilled => status == OrderStatus.filled;

  /// Remaining shares yet to be filled
  double get remainingQuantity => quantity - filledQuantity;

  /// Total monetary value of order based on execution price or target price
  double get totalValue =>
      quantity * (executionPrice ?? limitPrice ?? stopPrice ?? 0.0);

  OrderModel copyWith({
    String? id,
    String? symbol,
    OrderSide? side,
    OrderType? type,
    double? quantity,
    double? filledQuantity,
    double? price,
    double? limitPrice,
    double? stopPrice,
    double? executedPrice,
    double? executionPrice,
    double? fee,
    double? fees,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? executedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      side: side ?? this.side,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      filledQuantity: filledQuantity ?? this.filledQuantity,
      limitPrice: limitPrice ?? price ?? this.limitPrice,
      stopPrice: stopPrice ?? this.stopPrice,
      executionPrice: executionPrice ?? executedPrice ?? this.executionPrice,
      fees: fees ?? fee ?? this.fees,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      executedAt: executedAt ?? this.executedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'side': side.name,
      'type': type.name,
      'quantity': quantity,
      'filledQuantity': filledQuantity,
      'limitPrice': limitPrice,
      'stopPrice': stopPrice,
      'executionPrice': executionPrice,
      'fees': fees,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'executedAt': executedAt?.toIso8601String(),
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      side: OrderSide.fromString(json['side'] as String),
      type: OrderType.fromString(json['type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      filledQuantity: (json['filledQuantity'] as num?)?.toDouble() ?? 0.0,
      limitPrice: (json['limitPrice'] as num?)?.toDouble(),
      stopPrice: (json['stopPrice'] as num?)?.toDouble(),
      executionPrice: (json['executionPrice'] as num?)?.toDouble(),
      fees: (json['fees'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      executedAt: json['executedAt'] != null
          ? DateTime.parse(json['executedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        symbol,
        side,
        type,
        quantity,
        filledQuantity,
        limitPrice,
        stopPrice,
        executionPrice,
        fees,
        status,
        createdAt,
        executedAt,
      ];
}
