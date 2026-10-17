import '../../models/holding_model.dart';
import '../../models/order_model.dart';
import '../../models/transaction_model.dart';

/// Abstract Domain Contract for Paper Trading operations, cash balances, and positions
abstract class ITradingRepository {
  /// Initial virtual funds seeded for new paper trading accounts
  static const double initialVirtualCash = 100000.0;

  /// Retrieves the current available virtual cash balance
  Future<double> getVirtualCash();

  /// Updates the available virtual cash balance
  Future<void> setVirtualCash(double amount);

  /// Retrieves all active portfolio holdings
  Future<List<HoldingModel>> getHoldings();

  /// Persists the full list of holdings
  Future<void> saveHoldings(List<HoldingModel> holdings);

  /// Retrieves all orders (both pending and completed/cancelled)
  Future<List<OrderModel>> getOrders();

  /// Saves a newly placed order
  Future<void> saveOrder(OrderModel order);

  /// Updates an existing order (status, fill details, etc.)
  Future<void> updateOrder(OrderModel order);

  /// Retrieves all transaction ledger entries
  Future<List<TransactionModel>> getTransactions();

  /// Adds an audit transaction to the ledger
  Future<void> addTransaction(TransactionModel transaction);

  /// Resets virtual account back to $100,000 and clears all holdings & orders
  Future<void> resetVirtualAccount();
}
