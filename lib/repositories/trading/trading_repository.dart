import '../../models/holding_model.dart';
import '../../models/order_model.dart';
import '../../models/transaction_model.dart';
import '../../services/storage/i_storage_service.dart';
import 'i_trading_repository.dart';

/// Concrete Paper Trading Repository backed by [IStorageService]
class TradingRepository implements ITradingRepository {
  static const String keyCash = 'trading_virtual_cash';
  static const String keyHoldings = 'trading_holdings';
  static const String keyOrders = 'trading_orders';
  static const String keyTransactions = 'trading_transactions';

  final IStorageService storage;

  TradingRepository({required this.storage});

  @override
  Future<double> getVirtualCash() async {
    final raw = storage.getString(keyCash);
    if (raw == null) {
      // Seed default initial funds on fresh launch
      await setVirtualCash(ITradingRepository.initialVirtualCash);
      return ITradingRepository.initialVirtualCash;
    }
    return double.tryParse(raw) ?? ITradingRepository.initialVirtualCash;
  }

  @override
  Future<void> setVirtualCash(double amount) async {
    await storage.setString(keyCash, amount.toStringAsFixed(2));
  }

  @override
  Future<List<HoldingModel>> getHoldings() async {
    final rawList = storage.getJsonList(keyHoldings);
    if (rawList == null || rawList.isEmpty) {
      return [];
    }
    return rawList.map((e) => HoldingModel.fromJson(e)).toList();
  }

  @override
  Future<void> saveHoldings(List<HoldingModel> holdings) async {
    final jsonList = holdings.map((e) => e.toJson()).toList();
    await storage.setJsonList(keyHoldings, jsonList);
  }

  @override
  Future<List<OrderModel>> getOrders() async {
    final rawList = storage.getJsonList(keyOrders);
    if (rawList == null || rawList.isEmpty) {
      return [];
    }
    return rawList.map((e) => OrderModel.fromJson(e)).toList();
  }

  @override
  Future<void> saveOrder(OrderModel order) async {
    final current = await getOrders();
    // Prepend newer orders to the top of the history
    final updated = [order, ...current.where((e) => e.id != order.id)];
    await storage.setJsonList(keyOrders, updated.map((e) => e.toJson()).toList());
  }

  @override
  Future<void> updateOrder(OrderModel order) async {
    final current = await getOrders();
    final index = current.indexWhere((e) => e.id == order.id);
    if (index != -1) {
      current[index] = order;
      await storage.setJsonList(keyOrders, current.map((e) => e.toJson()).toList());
    } else {
      await saveOrder(order);
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final rawList = storage.getJsonList(keyTransactions);
    if (rawList == null || rawList.isEmpty) {
      return [];
    }
    return rawList.map((e) => TransactionModel.fromJson(e)).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final current = await getTransactions();
    final updated = [transaction, ...current];
    await storage.setJsonList(
      keyTransactions,
      updated.map((e) => e.toJson()).toList(),
    );
  }

  @override
  Future<void> resetVirtualAccount() async {
    await setVirtualCash(ITradingRepository.initialVirtualCash);
    await storage.setJsonList(keyHoldings, []);
    await storage.setJsonList(keyOrders, []);
    await storage.setJsonList(keyTransactions, [
      TransactionModel(
        id: 'tx_init_${DateTime.now().millisecondsSinceEpoch}',
        type: TransactionType.deposit,
        amount: ITradingRepository.initialVirtualCash,
        fees: 0.0,
        timestamp: DateTime.now(),
        reference: 'Initial Account Deposit',
      ).toJson(),
    ]);
  }
}
