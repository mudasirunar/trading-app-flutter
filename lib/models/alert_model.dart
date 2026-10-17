import 'package:equatable/equatable.dart';

/// Condition trigger for price alerts
enum AlertCondition {
  risesAbove,
  dropsBelow;

  String get label {
    switch (this) {
      case AlertCondition.risesAbove:
        return 'Price Rises Above';
      case AlertCondition.dropsBelow:
        return 'Price Drops Below';
    }
  }

  static AlertCondition fromString(String val) {
    return AlertCondition.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AlertCondition.risesAbove,
    );
  }
}

/// Operational status of an alert
enum AlertStatus {
  active,
  triggered,
  disabled;

  String get label {
    switch (this) {
      case AlertStatus.active:
        return 'Active';
      case AlertStatus.triggered:
        return 'Triggered';
      case AlertStatus.disabled:
        return 'Disabled';
    }
  }

  static AlertStatus fromString(String val) {
    return AlertStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AlertStatus.active,
    );
  }
}

/// Immutable model representing a conditional real-time price alert
class AlertModel extends Equatable {
  final String id;
  final String symbol;
  final double targetPrice;
  final AlertCondition condition;
  final AlertStatus status;
  final DateTime createdAt;
  final DateTime? triggeredAt;
  final double? triggeredPrice;
  final String? note;

  const AlertModel({
    required this.id,
    required this.symbol,
    required this.targetPrice,
    required this.condition,
    this.status = AlertStatus.active,
    required this.createdAt,
    this.triggeredAt,
    this.triggeredPrice,
    this.note,
  });

  bool get isActive => status == AlertStatus.active;
  bool get isTriggered => status == AlertStatus.triggered;
  bool get isDisabled => status == AlertStatus.disabled;

  /// Evaluates whether the given current price triggers this alert
  bool shouldTrigger(double currentPrice) {
    if (!isActive) return false;
    switch (condition) {
      case AlertCondition.risesAbove:
        return currentPrice >= targetPrice;
      case AlertCondition.dropsBelow:
        return currentPrice <= targetPrice;
    }
  }

  AlertModel copyWith({
    String? id,
    String? symbol,
    double? targetPrice,
    AlertCondition? condition,
    AlertStatus? status,
    DateTime? createdAt,
    DateTime? triggeredAt,
    double? triggeredPrice,
    String? note,
  }) {
    return AlertModel(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      targetPrice: targetPrice ?? this.targetPrice,
      condition: condition ?? this.condition,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      triggeredPrice: triggeredPrice ?? this.triggeredPrice,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'targetPrice': targetPrice,
      'condition': condition.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'triggeredAt': triggeredAt?.toIso8601String(),
      'triggeredPrice': triggeredPrice,
      'note': note,
    };
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      targetPrice: (json['targetPrice'] as num).toDouble(),
      condition: AlertCondition.fromString(json['condition'] as String),
      status: AlertStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      triggeredAt: json['triggeredAt'] != null
          ? DateTime.parse(json['triggeredAt'] as String)
          : null,
      triggeredPrice: (json['triggeredPrice'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        symbol,
        targetPrice,
        condition,
        status,
        createdAt,
        triggeredAt,
        triggeredPrice,
        note,
      ];
}
