import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/holding_model.dart';
import '../../models/order_model.dart';
import '../../models/transaction_model.dart';
import '../../repositories/trading/i_trading_repository.dart';
import 'trading_event.dart';
import 'trading_state.dart';

class TradingBloc extends Bloc<TradingEvent, TradingState> {
  final ITradingRepository repository;

  TradingBloc({required this.repository})
      : super(const TradingInitial()) {
    on<TradingInitialized>(_onTradingInitialized);
    on<OrderSubmitted>(_onOrderSubmitted);
    on<OrderCancelled>(_onOrderCancelled);
    on<MarketTickEvaluated>(_onMarketTickEvaluated);
    on<VirtualAccountReset>(_onVirtualAccountReset);
  }

  Future<void> _onTradingInitialized(
    TradingInitialized event,
    Emitter<TradingState> emit,
  ) async {
    emit(const TradingLoading());
    try {
      final cash = await repository.getVirtualCash();
      final holdings = await repository.getHoldings();
      final orders = await repository.getOrders();
      final transactions = await repository.getTransactions();

      emit(TradingLoaded(
        virtualCash: cash,
        holdings: holdings,
        orders: orders,
        transactions: transactions,
      ));
    } catch (e) {
      emit(TradingActionFailure(
        errorMessage: 'Failed to initialize trading account: $e',
      ));
    }
  }

  Future<void> _onOrderSubmitted(
    OrderSubmitted event,
    Emitter<TradingState> emit,
  ) async {
    final current = state;
    if (current is! TradingLoaded) return;

    if (event.quantity <= 0) {
      emit(TradingActionFailure(
        errorMessage: 'Order quantity must be greater than zero.',
        previousState: current,
      ));
      emit(current);
      return;
    }

    const double fixedFee = 1.0; // Institutional simulated fee ($1.00)
    final now = DateTime.now();
    final orderId = 'ord_${now.millisecondsSinceEpoch}_${event.instrument.symbol}';

    // 1. Validation for Buy Orders
    if (event.side == OrderSide.buy) {
      double estimatedPrice = event.instrument.price;
      if (event.type == OrderType.limit && event.limitPrice != null) {
        estimatedPrice = event.limitPrice!;
      } else if (event.type == OrderType.stopLoss && event.stopPrice != null) {
        estimatedPrice = event.stopPrice!;
      }

      final requiredCapital = (event.quantity * estimatedPrice) + fixedFee;
      if (current.virtualCash < requiredCapital) {
        emit(TradingActionFailure(
          errorMessage:
              'Insufficient buying power. Required: \$${requiredCapital.toStringAsFixed(2)}, Available: \$${current.virtualCash.toStringAsFixed(2)}',
          previousState: current,
        ));
        emit(current);
        return;
      }
    }

    // 2. Validation for Sell Orders
    if (event.side == OrderSide.sell) {
      final availableShares = current.getAvailableShares(event.instrument.symbol);
      if (availableShares < event.quantity) {
        emit(TradingActionFailure(
          errorMessage:
              'Insufficient shares. Available: ${availableShares.toStringAsFixed(0)}, Requested: ${event.quantity.toStringAsFixed(0)}',
          previousState: current,
        ));
        emit(current);
        return;
      }
    }

    // 3. Execution Branch: Market Orders (Instant Fill)
    if (event.type == OrderType.market) {
      final execPrice = event.instrument.price;
      final execValue = event.quantity * execPrice;

      if (event.side == OrderSide.buy) {
        final totalCost = execValue + fixedFee;
        final newCash = current.virtualCash - totalCost;

        // Update Holdings
        final existingHolding = current.getHolding(event.instrument.symbol);
        List<HoldingModel> updatedHoldings;
        if (existingHolding != null) {
          final newQty = existingHolding.quantity + event.quantity;
          final newAvgCost =
              (existingHolding.totalCost + execValue) / newQty;
          final updated = existingHolding.copyWith(
            quantity: newQty,
            averageCost: newAvgCost,
            currentPrice: execPrice,
          );
          updatedHoldings = current.holdings
              .map((h) => h.symbol == updated.symbol ? updated : h)
              .toList();
        } else {
          final newHolding = HoldingModel(
            symbol: event.instrument.symbol,
            quantity: event.quantity,
            averageCost: execPrice,
            currentPrice: execPrice,
          );
          updatedHoldings = [newHolding, ...current.holdings];
        }

        final filledOrder = OrderModel(
          id: orderId,
          symbol: event.instrument.symbol,
          side: event.side,
          type: event.type,
          quantity: event.quantity,
          filledQuantity: event.quantity,
          executionPrice: execPrice,
          fees: fixedFee,
          status: OrderStatus.filled,
          createdAt: now,
          executedAt: now,
        );

        final transaction = TransactionModel(
          id: 'tx_${now.millisecondsSinceEpoch}',
          type: TransactionType.buy,
          amount: -totalCost,
          symbol: event.instrument.symbol,
          quantity: event.quantity,
          price: execPrice,
          fees: fixedFee,
          timestamp: now,
          reference: orderId,
        );

        await repository.setVirtualCash(newCash);
        await repository.saveHoldings(updatedHoldings);
        await repository.saveOrder(filledOrder);
        await repository.addTransaction(transaction);

        emit(current.copyWith(
          virtualCash: newCash,
          holdings: updatedHoldings,
          orders: [filledOrder, ...current.orders],
          transactions: [transaction, ...current.transactions],
          lastActionMessage:
              'Bought ${event.quantity.toStringAsFixed(0)} ${event.instrument.symbol} @ \$${execPrice.toStringAsFixed(2)}',
        ));
        return;
      } else {
        // Market Sell
        final netProceeds = execValue - fixedFee;
        final newCash = current.virtualCash + netProceeds;

        final existingHolding = current.getHolding(event.instrument.symbol)!;
        final remainingQty = existingHolding.quantity - event.quantity;

        List<HoldingModel> updatedHoldings;
        if (remainingQty <= 0.0001) {
          updatedHoldings = current.holdings
              .where((h) => h.symbol != event.instrument.symbol)
              .toList();
        } else {
          final updated = existingHolding.copyWith(
            quantity: remainingQty,
            currentPrice: execPrice,
          );
          updatedHoldings = current.holdings
              .map((h) => h.symbol == updated.symbol ? updated : h)
              .toList();
        }

        final filledOrder = OrderModel(
          id: orderId,
          symbol: event.instrument.symbol,
          side: event.side,
          type: event.type,
          quantity: event.quantity,
          filledQuantity: event.quantity,
          executionPrice: execPrice,
          fees: fixedFee,
          status: OrderStatus.filled,
          createdAt: now,
          executedAt: now,
        );

        final transaction = TransactionModel(
          id: 'tx_${now.millisecondsSinceEpoch}',
          type: TransactionType.sell,
          amount: netProceeds,
          symbol: event.instrument.symbol,
          quantity: event.quantity,
          price: execPrice,
          fees: fixedFee,
          timestamp: now,
          reference: orderId,
        );

        await repository.setVirtualCash(newCash);
        await repository.saveHoldings(updatedHoldings);
        await repository.saveOrder(filledOrder);
        await repository.addTransaction(transaction);

        emit(current.copyWith(
          virtualCash: newCash,
          holdings: updatedHoldings,
          orders: [filledOrder, ...current.orders],
          transactions: [transaction, ...current.transactions],
          lastActionMessage:
              'Sold ${event.quantity.toStringAsFixed(0)} ${event.instrument.symbol} @ \$${execPrice.toStringAsFixed(2)}',
        ));
        return;
      }
    }

    // 4. Execution Branch: Limit & Stop-Loss Orders (Queued Pending)
    double newCash = current.virtualCash;
    if (event.side == OrderSide.buy) {
      final targetPrice = event.limitPrice ?? event.stopPrice ?? event.instrument.price;
      final requiredCapital = (event.quantity * targetPrice) + fixedFee;
      // Reserve cash immediately
      newCash -= requiredCapital;
      await repository.setVirtualCash(newCash);
    }

    final pendingOrder = OrderModel(
      id: orderId,
      symbol: event.instrument.symbol,
      side: event.side,
      type: event.type,
      quantity: event.quantity,
      limitPrice: event.limitPrice,
      stopPrice: event.stopPrice,
      fees: fixedFee,
      status: OrderStatus.pending,
      createdAt: now,
    );

    await repository.saveOrder(pendingOrder);

    emit(current.copyWith(
      virtualCash: newCash,
      orders: [pendingOrder, ...current.orders],
      lastActionMessage:
          '${event.type.label} ${event.side.label} order placed for ${event.quantity.toStringAsFixed(0)} ${event.instrument.symbol}',
    ));
  }

  Future<void> _onOrderCancelled(
    OrderCancelled event,
    Emitter<TradingState> emit,
  ) async {
    final current = state;
    if (current is! TradingLoaded) return;

    final order = current.orders.cast<OrderModel?>().firstWhere(
          (o) => o?.id == event.orderId,
          orElse: () => null,
        );

    if (order == null || !order.isPending) {
      emit(TradingActionFailure(
        errorMessage: 'Only active pending orders can be cancelled.',
        previousState: current,
      ));
      emit(current);
      return;
    }

    double newCash = current.virtualCash;
    // Refund reserved cash if it was a pending buy order
    if (order.side == OrderSide.buy) {
      final targetPrice = order.limitPrice ?? order.stopPrice ?? 0.0;
      final reservedCapital = (order.quantity * targetPrice) + order.fees;
      newCash += reservedCapital;
      await repository.setVirtualCash(newCash);
    }

    final cancelledOrder = order.copyWith(
      status: OrderStatus.cancelled,
      executedAt: DateTime.now(),
    );

    await repository.updateOrder(cancelledOrder);

    final updatedOrders = current.orders
        .map((o) => o.id == cancelledOrder.id ? cancelledOrder : o)
        .toList();

    emit(current.copyWith(
      virtualCash: newCash,
      orders: updatedOrders,
      lastActionMessage: 'Order cancelled for ${order.symbol}',
    ));
  }

  Future<void> _onMarketTickEvaluated(
    MarketTickEvaluated event,
    Emitter<TradingState> emit,
  ) async {
    final current = state;
    if (current is! TradingLoaded) return;

    final tick = event.instrument;
    final now = DateTime.now();

    // 1. Update live price for any existing holding of this symbol
    List<HoldingModel> updatedHoldings = current.holdings.map((h) {
      if (h.symbol.toUpperCase() == tick.symbol.toUpperCase()) {
        return h.copyWith(currentPrice: tick.price);
      }
      return h;
    }).toList();

    // 2. Evaluate all pending orders for this symbol
    final pendingForSymbol = current.pendingOrders
        .where((o) => o.symbol.toUpperCase() == tick.symbol.toUpperCase())
        .toList();

    if (pendingForSymbol.isEmpty) {
      // Just update holding prices if changed
      if (updatedHoldings != current.holdings) {
        emit(current.copyWith(holdings: updatedHoldings));
      }
      return;
    }

    double runningCash = current.virtualCash;
    List<OrderModel> updatedOrders = List.from(current.orders);
    List<TransactionModel> newTransactions = [];
    String? fillNotification;

    for (final order in pendingForSymbol) {
      bool shouldFill = false;
      double execPrice = tick.price;

      if (order.side == OrderSide.buy) {
        if (order.type == OrderType.limit && order.limitPrice != null) {
          // Limit Buy: triggers when market price drops to or below limit
          if (tick.price <= order.limitPrice!) {
            shouldFill = true;
            execPrice = math.min(tick.price, order.limitPrice!);
          }
        } else if (order.type == OrderType.stopLoss && order.stopPrice != null) {
          // Stop Loss Buy: triggers when market price rises to or above stop
          if (tick.price >= order.stopPrice!) {
            shouldFill = true;
            execPrice = tick.price;
          }
        }
      } else {
        // Sell Orders
        if (order.type == OrderType.limit && order.limitPrice != null) {
          // Limit Sell: triggers when market price rises to or above limit
          if (tick.price >= order.limitPrice!) {
            shouldFill = true;
            execPrice = math.max(tick.price, order.limitPrice!);
          }
        } else if (order.type == OrderType.stopLoss && order.stopPrice != null) {
          // Stop Loss Sell: triggers when market price drops to or below stop
          if (tick.price <= order.stopPrice!) {
            shouldFill = true;
            execPrice = tick.price;
          }
        }
      }

      if (shouldFill) {
        final execValue = order.quantity * execPrice;

        if (order.side == OrderSide.buy) {
          // Price improvement refund (if limit price > execution price)
          final reservedPrice = order.limitPrice ?? order.stopPrice ?? execPrice;
          final priceImprovement = (reservedPrice - execPrice) * order.quantity;
          if (priceImprovement > 0) {
            runningCash += priceImprovement;
          }

          // Add to holdings
          final existing = updatedHoldings.cast<HoldingModel?>().firstWhere(
                (h) => h?.symbol.toUpperCase() == order.symbol.toUpperCase(),
                orElse: () => null,
              );

          if (existing != null) {
            final newQty = existing.quantity + order.quantity;
            final newAvgCost = (existing.totalCost + execValue) / newQty;
            final updated = existing.copyWith(
              quantity: newQty,
              averageCost: newAvgCost,
              currentPrice: execPrice,
            );
            updatedHoldings = updatedHoldings
                .map((h) => h.symbol == updated.symbol ? updated : h)
                .toList();
          } else {
            final newH = HoldingModel(
              symbol: order.symbol,
              quantity: order.quantity,
              averageCost: execPrice,
              currentPrice: execPrice,
            );
            updatedHoldings = [newH, ...updatedHoldings];
          }

          final tx = TransactionModel(
            id: 'tx_${now.millisecondsSinceEpoch}_${order.id}',
            type: TransactionType.buy,
            amount: -(execValue + order.fees),
            symbol: order.symbol,
            quantity: order.quantity,
            price: execPrice,
            fees: order.fees,
            timestamp: now,
            reference: order.id,
          );
          newTransactions.add(tx);
        } else {
          // Sell Order filled
          final netProceeds = execValue - order.fees;
          runningCash += netProceeds;

          final existing = updatedHoldings.cast<HoldingModel?>().firstWhere(
                (h) => h?.symbol.toUpperCase() == order.symbol.toUpperCase(),
                orElse: () => null,
              );

          if (existing != null) {
            final remainingQty = existing.quantity - order.quantity;
            if (remainingQty <= 0.0001) {
              updatedHoldings = updatedHoldings
                  .where((h) => h.symbol.toUpperCase() != order.symbol.toUpperCase())
                  .toList();
            } else {
              final updated = existing.copyWith(
                quantity: remainingQty,
                currentPrice: execPrice,
              );
              updatedHoldings = updatedHoldings
                  .map((h) => h.symbol == updated.symbol ? updated : h)
                  .toList();
            }
          }

          final tx = TransactionModel(
            id: 'tx_${now.millisecondsSinceEpoch}_${order.id}',
            type: TransactionType.sell,
            amount: netProceeds,
            symbol: order.symbol,
            quantity: order.quantity,
            price: execPrice,
            fees: order.fees,
            timestamp: now,
            reference: order.id,
          );
          newTransactions.add(tx);
        }

        final filled = order.copyWith(
          status: OrderStatus.filled,
          filledQuantity: order.quantity,
          executionPrice: execPrice,
          executedAt: now,
        );

        final orderIdx = updatedOrders.indexWhere((o) => o.id == order.id);
        if (orderIdx != -1) {
          updatedOrders[orderIdx] = filled;
        }

        await repository.updateOrder(filled);
        fillNotification =
            'Filled: ${order.type.label} ${order.side.label} ${order.quantity.toStringAsFixed(0)} ${order.symbol} @ \$${execPrice.toStringAsFixed(2)}';
      }
    }

    if (newTransactions.isNotEmpty) {
      await repository.setVirtualCash(runningCash);
      await repository.saveHoldings(updatedHoldings);
      for (final tx in newTransactions) {
        await repository.addTransaction(tx);
      }
    }

    emit(current.copyWith(
      virtualCash: runningCash,
      holdings: updatedHoldings,
      orders: updatedOrders,
      transactions: [...newTransactions, ...current.transactions],
      lastActionMessage: fillNotification ?? current.lastActionMessage,
    ));
  }

  Future<void> _onVirtualAccountReset(
    VirtualAccountReset event,
    Emitter<TradingState> emit,
  ) async {
    emit(const TradingLoading());
    try {
      await repository.resetVirtualAccount();
      final cash = await repository.getVirtualCash();
      final holdings = await repository.getHoldings();
      final orders = await repository.getOrders();
      final transactions = await repository.getTransactions();

      emit(TradingLoaded(
        virtualCash: cash,
        holdings: holdings,
        orders: orders,
        transactions: transactions,
        lastActionMessage: 'Account reset to \$100,000.00 virtual cash.',
      ));
    } catch (e) {
      emit(TradingActionFailure(
        errorMessage: 'Failed to reset virtual account: $e',
      ));
    }
  }
}
