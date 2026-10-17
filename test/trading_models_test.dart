import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/models/holding_model.dart';
import 'package:trading_app/models/order_model.dart';
import 'package:trading_app/models/transaction_model.dart';

void main() {
  group('OrderModel Tests', () {
    final fixedTime = DateTime(2026, 10, 17, 12, 0, 0);

    final testOrder = OrderModel(
      id: 'ord-123',
      symbol: 'AAPL',
      side: OrderSide.buy,
      type: OrderType.limit,
      quantity: 10.0,
      price: 150.0,
      executedPrice: 149.50,
      status: OrderStatus.filled,
      createdAt: fixedTime,
      executedAt: fixedTime.add(const Duration(seconds: 30)),
      fee: 1.0,
    );

    test('OrderModel instantiation and totalValue computation', () {
      expect(testOrder.id, equals('ord-123'));
      expect(testOrder.symbol, equals('AAPL'));
      expect(testOrder.side, equals(OrderSide.buy));
      expect(testOrder.type, equals(OrderType.limit));
      expect(testOrder.status, equals(OrderStatus.filled));
      // Uses executedPrice when present
      expect(testOrder.totalValue, equals(10.0 * 149.50));
    });

    test('OrderModel totalValue falls back to price or 0', () {
      final pendingLimit = OrderModel(
        id: 'ord-124',
        symbol: 'TSLA',
        side: OrderSide.sell,
        type: OrderType.limit,
        quantity: 5.0,
        price: 200.0,
        status: OrderStatus.pending,
        createdAt: fixedTime,
      );
      expect(pendingLimit.totalValue, equals(1000.0));

      final marketNoExec = OrderModel(
        id: 'ord-125',
        symbol: 'NVDA',
        side: OrderSide.buy,
        type: OrderType.market,
        quantity: 2.0,
        status: OrderStatus.pending,
        createdAt: fixedTime,
      );
      expect(marketNoExec.totalValue, equals(0.0));
    });

    test('toJson and fromJson round-trip serialization', () {
      final json = testOrder.toJson();
      final reconstituted = OrderModel.fromJson(json);

      expect(reconstituted, equals(testOrder));
      expect(reconstituted.side, equals(OrderSide.buy));
      expect(reconstituted.type, equals(OrderType.limit));
      expect(reconstituted.status, equals(OrderStatus.filled));
      expect(reconstituted.fee, equals(1.0));
    });

    test('copyWith updates properties properly', () {
      final cancelled = testOrder.copyWith(
        status: OrderStatus.cancelled,
        fee: 0.5,
      );

      expect(cancelled.status, equals(OrderStatus.cancelled));
      expect(cancelled.fee, equals(0.5));
      expect(cancelled.id, equals(testOrder.id));
      expect(cancelled.symbol, equals(testOrder.symbol));
    });
  });

  group('HoldingModel Tests', () {
    test('HoldingModel financial metrics calculation', () {
      const holding = HoldingModel(
        symbol: 'AAPL',
        quantity: 10.0,
        averageCost: 150.0,
        currentPrice: 165.0,
      );

      expect(holding.totalCost, equals(1500.0));
      expect(holding.marketValue, equals(1650.0));
      expect(holding.unrealizedPL, equals(150.0));
      expect(holding.unrealizedPLPercent, closeTo(10.0, 0.001));
      expect(holding.isProfitable, isTrue);
    });

    test('HoldingModel handles loss calculations', () {
      const holding = HoldingModel(
        symbol: 'TSLA',
        quantity: 4.0,
        averageCost: 200.0,
        currentPrice: 180.0,
      );

      expect(holding.totalCost, equals(800.0));
      expect(holding.marketValue, equals(720.0));
      expect(holding.unrealizedPL, equals(-80.0));
      expect(holding.unrealizedPLPercent, closeTo(-10.0, 0.001));
      expect(holding.isProfitable, isFalse);
    });

    test('HoldingModel handles zero cost edge case', () {
      const zeroCostHolding = HoldingModel(
        symbol: 'GIFT',
        quantity: 1.0,
        averageCost: 0.0,
        currentPrice: 10.0,
      );

      expect(zeroCostHolding.unrealizedPLPercent, equals(0.0));
    });

    test('HoldingModel toJson and fromJson serialization', () {
      const holding = HoldingModel(
        symbol: 'BTC',
        quantity: 1.5,
        averageCost: 60000.0,
        currentPrice: 65000.0,
      );

      final json = holding.toJson();
      final reconstituted = HoldingModel.fromJson(json);

      expect(reconstituted, equals(holding));
      expect(reconstituted.marketValue, equals(holding.marketValue));
    });

    test('HoldingModel copyWith updates correctly', () {
      const holding = HoldingModel(
        symbol: 'ETH',
        quantity: 5.0,
        averageCost: 3000.0,
        currentPrice: 3100.0,
      );

      final updated = holding.copyWith(currentPrice: 3400.0, quantity: 6.0);
      expect(updated.currentPrice, equals(3400.0));
      expect(updated.quantity, equals(6.0));
      expect(updated.averageCost, equals(3000.0));
    });
  });

  group('TransactionModel Tests', () {
    final fixedTime = DateTime(2026, 10, 17, 14, 30);

    final transaction = TransactionModel(
      id: 'tx-001',
      type: TransactionType.buy,
      symbol: 'AAPL',
      quantity: 5.0,
      price: 150.0,
      amount: -750.0,
      fees: 1.0,
      timestamp: fixedTime,
      reference: 'ord-123',
    );

    test('TransactionModel getters and properties', () {
      expect(transaction.id, equals('tx-001'));
      expect(transaction.type, equals(TransactionType.buy));
      expect(transaction.symbol, equals('AAPL'));
      expect(transaction.amount, equals(-750.0));
      expect(transaction.fees, equals(1.0));
      expect(transaction.timestamp, equals(fixedTime));
      expect(transaction.reference, equals('ord-123'));
    });

    test('TransactionModel toJson and fromJson round-trip', () {
      final json = transaction.toJson();
      final reconstituted = TransactionModel.fromJson(json);

      expect(reconstituted, equals(transaction));
      expect(reconstituted.type, equals(TransactionType.buy));
      expect(reconstituted.reference, equals('ord-123'));
    });

    test('TransactionModel copyWith updates properties', () {
      final updated = transaction.copyWith(
        fees: 2.50,
        reference: 'ord-updated',
      );
      expect(updated.fees, equals(2.50));
      expect(updated.reference, equals('ord-updated'));
      expect(updated.id, equals(transaction.id));
    });
  });
}
