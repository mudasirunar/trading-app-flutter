import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/trading/trading_bloc.dart';
import '../../../blocs/trading/trading_event.dart';
import '../../../blocs/trading/trading_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../models/instrument_model.dart';
import '../../../models/order_model.dart';

class OrderTicketBottomSheet extends StatefulWidget {
  final InstrumentModel instrument;
  final OrderSide initialSide;

  const OrderTicketBottomSheet({
    super.key,
    required this.instrument,
    this.initialSide = OrderSide.buy,
  });

  static Future<void> show(
    BuildContext context, {
    required InstrumentModel instrument,
    OrderSide initialSide = OrderSide.buy,
  }) {
    return AppBottomSheet.show(
      context: context,
      child: OrderTicketBottomSheet(
        instrument: instrument,
        initialSide: initialSide,
      ),
    );
  }

  @override
  State<OrderTicketBottomSheet> createState() => _OrderTicketBottomSheetState();
}

class _OrderTicketBottomSheetState extends State<OrderTicketBottomSheet> {
  late OrderSide _side;
  OrderType _type = OrderType.market;

  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController();

  double _quantity = 1.0;
  double? _targetPrice;

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide;
    _priceController.text = widget.instrument.price.toStringAsFixed(2);
    _targetPrice = widget.instrument.price;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onSideChanged(OrderSide side) {
    if (_side == side) return;
    AppHaptics.selection();
    setState(() {
      _side = side;
    });
  }

  void _onTypeChanged(OrderType type) {
    if (_type == type) return;
    AppHaptics.selection();
    setState(() {
      _type = type;
      if (_type == OrderType.market) {
        _targetPrice = widget.instrument.price;
        _priceController.text = widget.instrument.price.toStringAsFixed(2);
      }
    });
  }

  void _adjustQuantity(double delta) {
    AppHaptics.selection();
    final newQty = (_quantity + delta).clamp(1.0, 99999.0);
    setState(() {
      _quantity = newQty;
      _qtyController.text = _quantity.toStringAsFixed(0);
    });
  }

  void _applyPercentage(double pct, TradingLoaded trading) {
    AppHaptics.selection();
    if (_side == OrderSide.buy) {
      final availableCash = trading.virtualCash;
      final effectivePrice = _getEffectivePrice();
      if (effectivePrice <= 0) return;
      final targetCost = (availableCash * pct) - 1.0; // reserve $1 fee
      if (targetCost <= 0) return;
      final shares = (targetCost / effectivePrice).floorToDouble().clamp(1.0, 99999.0);
      setState(() {
        _quantity = shares;
        _qtyController.text = _quantity.toStringAsFixed(0);
      });
    } else {
      final availableShares = trading.getAvailableShares(widget.instrument.symbol);
      if (availableShares <= 0) return;
      final shares = (availableShares * pct).floorToDouble().clamp(1.0, availableShares);
      setState(() {
        _quantity = shares;
        _qtyController.text = _quantity.toStringAsFixed(0);
      });
    }
  }

  double _getEffectivePrice() {
    if (_type == OrderType.market) {
      return widget.instrument.price;
    }
    return _targetPrice ?? widget.instrument.price;
  }

  void _submitOrder(BuildContext context, TradingLoaded trading) {
    final effectivePrice = _getEffectivePrice();
    const double fee = 1.0;

    if (_quantity <= 0) {
      AppSnackBar.showWarning(
        context,
        'Please enter a quantity greater than zero.',
        title: 'Invalid Quantity',
      );
      return;
    }

    if (_side == OrderSide.buy) {
      final totalCost = (_quantity * effectivePrice) + fee;
      if (trading.virtualCash < totalCost) {
        AppHaptics.error();
        AppSnackBar.showError(
          context,
          'Required: \$${totalCost.toStringAsFixed(2)}, Available: \$${trading.virtualCash.toStringAsFixed(2)}',
          title: 'Insufficient Buying Power',
        );
        return;
      }
    } else {
      final availableShares = trading.getAvailableShares(widget.instrument.symbol);
      if (availableShares < _quantity) {
        AppHaptics.error();
        AppSnackBar.showError(
          context,
          'Available: ${availableShares.toStringAsFixed(0)}, Requested: ${_quantity.toStringAsFixed(0)}',
          title: 'Insufficient Shares',
        );
        return;
      }
    }

    AppHaptics.medium();

    context.read<TradingBloc>().add(
          OrderSubmitted(
            instrument: widget.instrument,
            side: _side,
            type: _type,
            quantity: _quantity,
            limitPrice: _type == OrderType.limit ? _targetPrice : null,
            stopPrice: _type == OrderType.stopLoss ? _targetPrice : null,
          ),
        );

    Navigator.of(context).pop();

    AppHaptics.success();
    AppSnackBar.showSuccess(
      context,
      '${_type.label} ${_side.label} for ${_quantity.toStringAsFixed(0)} ${widget.instrument.symbol} @ \$${effectivePrice.toStringAsFixed(2)} submitted.',
      title: 'Order Placed Successfully',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceSubtle = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocBuilder<TradingBloc, TradingState>(
      builder: (context, state) {
        if (state is! TradingLoaded) {
          return const Padding(
            padding: EdgeInsets.all(AppStyles.space32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final effectivePrice = _getEffectivePrice();
        const double fee = 1.0;
        final subtotal = _quantity * effectivePrice;
        final totalCost = _side == OrderSide.buy ? subtotal + fee : subtotal - fee;
        final availableCash = state.virtualCash;
        final availableShares = state.getAvailableShares(widget.instrument.symbol);

        final bool hasInsufficientFunds = _side == OrderSide.buy && totalCost > availableCash;
        final bool hasInsufficientShares = _side == OrderSide.sell && _quantity > availableShares;
        final bool canSubmit = !hasInsufficientFunds && !hasInsufficientShares && _quantity > 0;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header: Symbol, Name, Price, Change Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.instrument.symbol.substring(
                        0,
                        widget.instrument.symbol.length.clamp(1, 3),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.instrument.symbol,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        Text(
                          widget.instrument.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${widget.instrument.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      Text(
                        '${widget.instrument.isPositive ? '+' : ''}${widget.instrument.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: widget.instrument.isPositive
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Side Toggle Pill (Buy / Sell)
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onSideChanged(OrderSide.buy),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: _side == OrderSide.buy
                                ? AppColors.accentGreen
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Buy ${widget.instrument.symbol}',
                            style: TextStyle(
                              color: _side == OrderSide.buy ? Colors.white : textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onSideChanged(OrderSide.sell),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: _side == OrderSide.sell
                                ? AppColors.accentRed
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sell ${widget.instrument.symbol}',
                            style: TextStyle(
                              color: _side == OrderSide.sell ? Colors.white : textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Order Type Segmented Selector
              Row(
                children: OrderType.values.map((type) {
                  final isSelected = _type == type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => _onTypeChanged(type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryBlue : surfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryBlue : borderColor,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 4. Dynamic Price Input (if Limit or Stop-Loss)
              if (_type != OrderType.market) ...[
                Row(
                  children: [
                    Text(
                      _type == OrderType.limit ? 'Limit Target Price' : 'Stop Trigger Price',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Market: \$${widget.instrument.price.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('\$', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _targetPrice = double.tryParse(val) ?? widget.instrument.price;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 5. Quantity Stepper Section
              Row(
                children: [
                  Text(
                    'Shares Quantity',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (_side == OrderSide.buy)
                    Text(
                      'Buying Power: \$${availableCash.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    )
                  else
                    Text(
                      'Available: ${availableShares.toStringAsFixed(0)} Shares',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () => _adjustQuantity(-1.0),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _qtyController,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 1.0;
                          setState(() {
                            _quantity = parsed.clamp(0.0, 99999.0);
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => _adjustQuantity(1.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 6. Quick Percentage Allocation Chips (25%, 50%, 75%, 100%)
              Row(
                children: [0.25, 0.50, 0.75, 1.00].map((pct) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => _applyPercentage(pct, state),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: surfaceSubtle,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: borderColor),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${(pct * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 7. Order Summary Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estimated Subtotal', style: TextStyle(fontSize: 12, color: textSecondary)),
                        Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Simulated Commission Fee', style: TextStyle(fontSize: 12, color: textSecondary)),
                        const Text('\$1.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _side == OrderSide.buy ? 'Total Estimated Cost' : 'Net Estimated Proceeds',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '\$${totalCost.clamp(0.0, 99999999.0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _side == OrderSide.buy
                                ? (hasInsufficientFunds ? AppColors.accentRed : null)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 8. Warning Banner if Insufficient
              if (hasInsufficientFunds) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.accentRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Insufficient Buying Power (\$$availableCash available)',
                          style: const TextStyle(
                            color: AppColors.accentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (hasInsufficientShares) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.accentRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Insufficient Shares (${availableShares.toStringAsFixed(0)} available)',
                          style: const TextStyle(
                            color: AppColors.accentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // 9. Order Submission Button
              AppButton(
                text: canSubmit
                    ? '${_side.label} ${_quantity.toStringAsFixed(0)} ${widget.instrument.symbol}'
                    : (_side == OrderSide.buy
                        ? 'Insufficient Buying Power'
                        : 'Insufficient Shares'),
                onPressed: canSubmit ? () => _submitOrder(context, state) : null,
                variant: _side == OrderSide.buy ? AppButtonVariant.success : AppButtonVariant.danger,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
  }
}
