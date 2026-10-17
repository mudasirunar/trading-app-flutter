import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/models/holding_model.dart';
import 'package:trading_app/models/order_model.dart';
import 'package:trading_app/models/transaction_model.dart';
import 'package:trading_app/repositories/trading/trading_repository.dart';
import 'package:trading_app/services/storage/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storageService;
  late TradingRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = LocalStorageService(preferences: prefs);
    await storageService.init();
    repository = TradingRepository(storage: storageService);
  });

  group('TradingRepository Unit Tests', () {
    test('Initial virtual cash defaults to 100,000.0', () async {
      final cash = await repository.getVirtualCash();
      expect(cash, equals(100000.0));
    });

    test('setVirtualCash persists and updates balance', () async {
      await repository.setVirtualCash(87500.50);
      final cash = await repository.getVirtualCash();
      expect(cash, equals(87500.50));
    });

    test('saveHoldings persists list of holdings', () async {
      expect(await repository.getHoldings(), isEmpty);

      const holdings = [
        HoldingModel(
          symbol: 'AAPL',
          quantity: 10.0,
          averageCost: 150.0,
          currentPrice: 155.0,
        ),
        HoldingModel(
          symbol: 'TSLA',
          quantity: 5.0,
          averageCost: 200.0,
          currentPrice: 210.0,
        ),
      ];

      await repository.saveHoldings(holdings);

      final retrieved = await repository.getHoldings();
      expect(retrieved.length, equals(2));
      expect(retrieved.first.symbol, equals('AAPL'));
      expect(retrieved.first.quantity, equals(10.0));
      expect(retrieved.last.symbol, equals('TSLA'));
    });

    test('saveOrder, updateOrder and getOrders persist and sort descending', () async {
      final now = DateTime.now();

      final order1 = OrderModel(
        id: 'ord-1',
        symbol: 'NVDA',
        side: OrderSide.buy,
        type: OrderType.market,
        quantity: 5.0,
        status: OrderStatus.filled,
        createdAt: now.subtract(const Duration(minutes: 5)),
      );

      final order2 = OrderModel(
        id: 'ord-2',
        symbol: 'TSLA',
        side: OrderSide.sell,
        type: OrderType.limit,
        quantity: 2.0,
        limitPrice: 250.0,
        status: OrderStatus.pending,
        createdAt: now,
      );

      await repository.saveOrder(order1);
      await repository.saveOrder(order2);

      final orders = await repository.getOrders();
      expect(orders.length, equals(2));
      expect(orders.first.id, equals('ord-2'));
      expect(orders.last.id, equals('ord-1'));

      final updatedOrder2 = order2.copyWith(status: OrderStatus.cancelled);
      await repository.updateOrder(updatedOrder2);

      final reloadedOrders = await repository.getOrders();
      expect(reloadedOrders.first.status, equals(OrderStatus.cancelled));
    });

    test('addTransaction persists and sorts descending by timestamp', () async {
      final now = DateTime.now();

      final tx1 = TransactionModel(
        id: 'tx-1',
        type: TransactionType.deposit,
        amount: 100000.0,
        timestamp: now.subtract(const Duration(hours: 1)),
        reference: 'seed-deposit',
      );

      final tx2 = TransactionModel(
        id: 'tx-2',
        type: TransactionType.buy,
        symbol: 'AAPL',
        quantity: 10.0,
        price: 150.0,
        amount: -1500.0,
        timestamp: now,
        reference: 'ord-1',
      );

      await repository.addTransaction(tx1);
      await repository.addTransaction(tx2);

      final transactions = await repository.getTransactions();
      expect(transactions.length, equals(2));
      expect(transactions.first.id, equals('tx-2'));
      expect(transactions.last.id, equals('tx-1'));
    });

    test('resetVirtualAccount purges all data and resets cash to 100,000.0', () async {
      await repository.setVirtualCash(45000.0);
      await repository.saveHoldings([
        const HoldingModel(
          symbol: 'MSFT',
          quantity: 10,
          averageCost: 300,
          currentPrice: 310,
        ),
      ]);
      await repository.saveOrder(OrderModel(
        id: 'ord-test',
        symbol: 'MSFT',
        side: OrderSide.buy,
        type: OrderType.market,
        quantity: 10,
        status: OrderStatus.filled,
        createdAt: DateTime.now(),
      ));
      await repository.addTransaction(TransactionModel(
        id: 'tx-test',
        type: TransactionType.buy,
        amount: -3000,
        timestamp: DateTime.now(),
        reference: 'ord-test',
      ));

      await repository.resetVirtualAccount();

      expect(await repository.getVirtualCash(), equals(100000.0));
      expect(await repository.getHoldings(), isEmpty);
      final resetTransactions = await repository.getTransactions();
      expect(resetTransactions.length, equals(1));
      expect(resetTransactions.first.type, equals(TransactionType.deposit));
      expect(resetTransactions.first.amount, equals(100000.0));
    });
  });
}
