import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/models/holding_model.dart';
import 'package:trading_app/models/order_model.dart';
import 'package:trading_app/blocs/trading/trading_state.dart';

void main() {
  group('Portfolio Mathematical Formulas', () {
    test('HoldingModel calculates totalCost and marketValue correctly', () {
      const holding = HoldingModel(
        symbol: 'AAPL',
        quantity: 10.0,
        averageCost: 150.0,
        currentPrice: 180.0,
      );

      expect(holding.totalCost, 1500.0);
      expect(holding.marketValue, 1800.0);
      expect(holding.unrealizedPL, 300.0);
      expect(holding.unrealizedPLPercent, closeTo(20.0, 0.001));
      expect(holding.isProfitable, isTrue);
    });

    test('HoldingModel handles losing position correctly', () {
      const holding = HoldingModel(
        symbol: 'TSLA',
        quantity: 5.0,
        averageCost: 250.0,
        currentPrice: 200.0,
      );

      expect(holding.totalCost, 1250.0);
      expect(holding.marketValue, 1000.0);
      expect(holding.unrealizedPL, -250.0);
      expect(holding.unrealizedPLPercent, closeTo(-20.0, 0.001));
      expect(holding.isProfitable, isFalse);
    });

    test('HoldingModel handles zero cost basis safely without division by zero', () {
      const holding = HoldingModel(
        symbol: 'FREE',
        quantity: 10.0,
        averageCost: 0.0,
        currentPrice: 10.0,
      );

      expect(holding.totalCost, 0.0);
      expect(holding.unrealizedPL, 100.0);
      expect(holding.unrealizedPLPercent, 0.0);
    });

    test('TradingLoaded aggregates totalInvested and market value across multiple positions', () {
      final holdings = [
        const HoldingModel(
          symbol: 'AAPL',
          quantity: 10.0,
          averageCost: 150.0,
          currentPrice: 180.0,
        ), // cost: 1500, val: 1800, pl: +300
        const HoldingModel(
          symbol: 'MSFT',
          quantity: 5.0,
          averageCost: 400.0,
          currentPrice: 420.0,
        ), // cost: 2000, val: 2100, pl: +100
        const HoldingModel(
          symbol: 'GOOGL',
          quantity: 20.0,
          averageCost: 175.0,
          currentPrice: 160.0,
        ), // cost: 3500, val: 3200, pl: -300
      ];

      final state = TradingLoaded(
        virtualCash: 25000.0,
        holdings: holdings,
        orders: const [],
        transactions: const [],
      );

      expect(state.totalInvested, 7000.0);
      expect(state.totalHoldingsMarketValue, 7100.0);
      expect(state.totalPortfolioValue, 32100.0);
      expect(state.overallUnrealizedPL, 100.0);
      // (100 / 7000) * 100 = 1.42857%
      expect(state.overallUnrealizedPLPercent, closeTo(1.42857, 0.001));
    });

    test('TradingLoaded calculates available shares locking pending sell orders', () {
      const holding = HoldingModel(
        symbol: 'NVDA',
        quantity: 50.0,
        averageCost: 100.0,
        currentPrice: 120.0,
      );

      final pendingSellOrder1 = OrderModel(
        id: 'ord-1',
        symbol: 'NVDA',
        side: OrderSide.sell,
        type: OrderType.limit,
        quantity: 15.0,
        limitPrice: 130.0,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      final pendingSellOrder2 = OrderModel(
        id: 'ord-2',
        symbol: 'NVDA',
        side: OrderSide.sell,
        type: OrderType.stopLoss,
        quantity: 10.0,
        stopPrice: 110.0,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      // Pending buy order should NOT lock shares
      final pendingBuyOrder = OrderModel(
        id: 'ord-3',
        symbol: 'NVDA',
        side: OrderSide.buy,
        type: OrderType.limit,
        quantity: 25.0,
        limitPrice: 105.0,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      final state = TradingLoaded(
        virtualCash: 10000.0,
        holdings: [holding],
        orders: [pendingSellOrder1, pendingSellOrder2, pendingBuyOrder],
        transactions: const [],
      );

      // Total quantity: 50, locked in sells: 15 + 10 = 25 -> Available: 25
      expect(state.getAvailableShares('NVDA'), 25.0);
      expect(state.getAvailableShares('UNKNOWN'), 0.0);
    });

    test('Multi-lot weighted average cost computation logic', () {
      // Lot 1: 10 shares @ $100 = $1,000
      double qty = 10.0;
      double avgCost = 100.0;
      double totalCost = qty * avgCost;

      // Lot 2: buy 10 shares @ $150 = $1,500
      double newQty = 10.0;
      double newPrice = 150.0;
      double newTotalCost = totalCost + (newQty * newPrice); // 2,500
      qty += newQty; // 20
      avgCost = newTotalCost / qty; // 125.0

      expect(avgCost, 125.0);

      // Lot 3: buy 5 shares @ $200 = $1,000
      double lot3Qty = 5.0;
      double lot3Price = 200.0;
      newTotalCost = (qty * avgCost) + (lot3Qty * lot3Price); // 3,500
      qty += lot3Qty; // 25
      avgCost = newTotalCost / qty; // 140.0

      expect(avgCost, 140.0);
    });
  });
}
