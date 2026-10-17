import 'package:equatable/equatable.dart';

/// Transaction category in the audit ledger
enum TransactionType {
  deposit,
  buy,
  sell,
  fee;

  String get label {
    switch (this) {
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.buy:
        return 'Buy';
      case TransactionType.sell:
        return 'Sell';
      case TransactionType.fee:
        return 'Commission Fee';
    }
  }

  static TransactionType fromString(String val) {
    return TransactionType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TransactionType.buy,
    );
  }
}

/// Immutable Model representing an Auditable Financial Transaction in the ledger
class TransactionModel extends Equatable {
  final String id;
  final TransactionType type;
  final double amount; // Net cash flow (positive for deposit/sell, negative for buy/fee)
  final String? symbol;
  final double? quantity;
  final double? price;
  final double fees;
  final DateTime timestamp;
  final String reference;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.symbol,
    this.quantity,
    this.price,
    this.fees = 0.0,
    required this.timestamp,
    required this.reference,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'symbol': symbol,
      'quantity': quantity,
      'price': price,
      'fees': fees,
      'timestamp': timestamp.toIso8601String(),
      'reference': reference,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      symbol: json['symbol'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      fees: (json['fees'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
      reference: json['reference'] as String,
    );
  }

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? symbol,
    double? quantity,
    double? price,
    double? fees,
    DateTime? timestamp,
    String? reference,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      fees: fees ?? this.fees,
      timestamp: timestamp ?? this.timestamp,
      reference: reference ?? this.reference,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        symbol,
        quantity,
        price,
        fees,
        timestamp,
        reference,
      ];
}
