import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/alerts/alerts_bloc.dart';
import '../../../blocs/alerts/alerts_event.dart';
import '../../../blocs/market/market_bloc.dart';
import '../../../blocs/market/market_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../models/alert_model.dart';
import '../../../models/instrument_model.dart';

/// Modal bottom sheet allowing users to configure and submit a conditional Price Alert.
class CreateAlertSheet extends StatefulWidget {
  final InstrumentModel instrument;

  const CreateAlertSheet({
    super.key,
    required this.instrument,
  });

  static Future<void> show(BuildContext context, InstrumentModel instrument) {
    AppHaptics.selection();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateAlertSheet(instrument: instrument),
    );
  }

  @override
  State<CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends State<CreateAlertSheet> {
  late AlertCondition _condition;
  late TextEditingController _priceController;
  late TextEditingController _noteController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _condition = AlertCondition.risesAbove;
    // Default to +2% target
    final defaultTarget = widget.instrument.price * 1.02;
    _priceController =
        TextEditingController(text: defaultTarget.toStringAsFixed(2));
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  InstrumentModel _getLiveInstrument(BuildContext context) {
    final marketState = context.watch<MarketBloc>().state;
    if (marketState is MarketLoaded) {
      return marketState.instruments.firstWhere(
        (i) => i.symbol == widget.instrument.symbol,
        orElse: () => widget.instrument,
      );
    }
    return widget.instrument;
  }

  void _applyPercentageDelta(double percentDelta, double livePrice) {
    AppHaptics.selection();
    final newPrice = livePrice * (1.0 + (percentDelta / 100.0));
    setState(() {
      _condition = percentDelta >= 0
          ? AlertCondition.risesAbove
          : AlertCondition.dropsBelow;
      _priceController.text = newPrice.toStringAsFixed(2);
      _errorMessage = null;
    });
  }

  void _onPriceChanged(String value, double livePrice) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null && parsed > 0) {
      if (parsed > livePrice &&
          _condition != AlertCondition.risesAbove) {
        setState(() {
          _condition = AlertCondition.risesAbove;
          _errorMessage = null;
        });
      } else if (parsed < livePrice &&
          _condition != AlertCondition.dropsBelow) {
        setState(() {
          _condition = AlertCondition.dropsBelow;
          _errorMessage = null;
        });
      } else if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    }
  }

  void _submitAlert(double livePrice) {
    final parsedPrice = double.tryParse(_priceController.text.trim());
    if (parsedPrice == null || parsedPrice <= 0) {
      setState(() => _errorMessage = 'Please enter a valid target price.');
      AppHaptics.error();
      return;
    }

    if (_condition == AlertCondition.risesAbove &&
        parsedPrice <= livePrice) {
      setState(() => _errorMessage =
          'Target must rise above current live price (${FormatUtils.formatCurrency(livePrice)}).');
      AppHaptics.error();
      return;
    }

    if (_condition == AlertCondition.dropsBelow &&
        parsedPrice >= livePrice) {
      setState(() => _errorMessage =
          'Target must drop below current live price (${FormatUtils.formatCurrency(livePrice)}).');
      AppHaptics.error();
      return;
    }

    final now = DateTime.now();
    final alert = AlertModel(
      id: 'alert_${now.millisecondsSinceEpoch}',
      symbol: widget.instrument.symbol,
      targetPrice: parsedPrice,
      condition: _condition,
      status: AlertStatus.active,
      createdAt: now,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );

    AppHaptics.alertChime();
    context.read<AlertsBloc>().add(AlertCreated(alert));
    Navigator.of(context).pop();

    AppSnackBar.show(
      context,
      message:
          'Alert set for ${widget.instrument.symbol} at ${FormatUtils.formatCurrency(parsedPrice)}',
      type: AppSnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveInstrument = _getLiveInstrument(context);
    final currentPrice = liveInstrument.price;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        viewInsets > 0
            ? viewInsets + 14
            : (bottomPadding > 0 ? bottomPadding + 8 : 24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Fixed Header: Handle Bar & Title (Tapping or swiping DOWN here slides down the keyboard)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! > 5) {
                FocusScope.of(context).unfocus();
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.3),
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Fixed Header: Symbol & Live Market Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_rounded,
                              size: 18,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Set Price Alert',
                              style: AppStyles.headline.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.instrument.symbol} · ${widget.instrument.name}',
                          style:
                              AppStyles.caption.copyWith(color: textSecondary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          FormatUtils.formatCurrency(currentPrice),
                          style: AppStyles.titleMedium.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.bullGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Live Price',
                              style: AppStyles.caption.copyWith(
                                color: textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 12),

          // 3. Scrollable Input Body (Scroll freely without closing keyboard!)
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Condition Selector (Rises Above vs Drops Below)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ALERT DIRECTION',
                        style: AppStyles.caption.copyWith(
                          color: textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Auto-detects from target price',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildConditionButton(
                          condition: AlertCondition.risesAbove,
                          label: 'Rises Above',
                          subtitle:
                              '> ${FormatUtils.formatCurrency(currentPrice)}',
                          icon: Icons.trending_up_rounded,
                          activeColor: AppColors.bullGreen,
                          livePrice: currentPrice,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildConditionButton(
                          condition: AlertCondition.dropsBelow,
                          label: 'Drops Below',
                          subtitle:
                              '< ${FormatUtils.formatCurrency(currentPrice)}',
                          icon: Icons.trending_down_rounded,
                          activeColor: AppColors.bearRed,
                          livePrice: currentPrice,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Quick Percentage Chips
                  Text(
                    'QUICK TARGET PRESETS',
                    style: AppStyles.caption.copyWith(
                      color: textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPresetChip('+1%', 1.0, currentPrice, isBull: true),
                      const SizedBox(width: 6),
                      _buildPresetChip('+3%', 3.0, currentPrice, isBull: true),
                      const SizedBox(width: 6),
                      _buildPresetChip('+5%', 5.0, currentPrice, isBull: true),
                      const SizedBox(width: 8),
                      _buildPresetChip('-1%', -1.0, currentPrice, isBull: false),
                      const SizedBox(width: 6),
                      _buildPresetChip('-3%', -3.0, currentPrice, isBull: false),
                      const SizedBox(width: 6),
                      _buildPresetChip('-5%', -5.0, currentPrice, isBull: false),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Custom Price Input
                  Text(
                    'TARGET PRICE (\$)',
                    style: AppStyles.caption.copyWith(
                      color: textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    onChanged: (val) => _onPriceChanged(val, currentPrice),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceSecondary
                          : AppColors.lightSurfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.radius12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.radius12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.bearRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Live Dynamic Trigger Explanation Card
                  _buildLiveTriggerSummaryCard(
                    isDark: isDark,
                    currentPrice: currentPrice,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  const SizedBox(height: 14),

                  // Optional Note Input
                  TextField(
                    controller: _noteController,
                    style: TextStyle(color: textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText:
                          'Add optional note (e.g., Take Profit Target)...',
                      hintStyle:
                          TextStyle(color: textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurfaceSecondary
                          : AppColors.lightSurfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.radius12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.radius12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 4. Pinned Action Button (ALWAYS visible above the keyboard!)
          AppButton(
            text: 'Set Price Alert',
            icon: Icons.add_alert_rounded,
            variant: AppButtonVariant.primary,
            onPressed: () => _submitAlert(currentPrice),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionButton({
    required AlertCondition condition,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
    required double livePrice,
  }) {
    final isSelected = _condition == condition;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        final currentVal =
            double.tryParse(_priceController.text.trim()) ?? livePrice;
        setState(() {
          _condition = condition;
          if (condition == AlertCondition.risesAbove &&
              currentVal <= livePrice) {
            _priceController.text =
                (livePrice * 1.02).toStringAsFixed(2);
          } else if (condition == AlertCondition.dropsBelow &&
              currentVal >= livePrice) {
            _priceController.text =
                (livePrice * 0.98).toStringAsFixed(2);
          }
          _errorMessage = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark
                  ? AppColors.darkSurfaceSecondary
                  : AppColors.lightSurfaceSecondary),
          borderRadius: BorderRadius.circular(AppStyles.radius12),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? activeColor
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? activeColor
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.85)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTriggerSummaryCard({
    required bool isDark,
    required double currentPrice,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final parsed = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final diff = parsed - currentPrice;
    final diffPercent = currentPrice > 0 ? (diff / currentPrice) * 100 : 0.0;

    final isBull = parsed > currentPrice;
    final isNeutral = parsed <= 0 || (parsed - currentPrice).abs() < 0.001;

    final accentColor = isNeutral
        ? const Color(0xFFF59E0B)
        : (isBull ? AppColors.bullGreen : AppColors.bearRed);
    final badgeLabel = isNeutral
        ? 'TARGET = MARKET PRICE'
        : (isBull
            ? 'RISE TRIGGER (+${diffPercent.abs().toStringAsFixed(2)}%)'
            : 'DROP TRIGGER (-${diffPercent.abs().toStringAsFixed(2)}%)');
    final headline = isNeutral
        ? 'Target equals current market price'
        : (isBull
            ? 'Triggers when ${widget.instrument.symbol} rises above ${FormatUtils.formatCurrency(parsed)}'
            : 'Triggers when ${widget.instrument.symbol} drops below ${FormatUtils.formatCurrency(parsed)}');
    final subtitle = isNeutral
        ? 'Enter a price higher (for breakout) or lower (for dip) to monitor.'
        : (isBull
            ? 'Fires alert as soon as price climbs +${diffPercent.abs().toStringAsFixed(2)}% from live price (${FormatUtils.formatCurrency(currentPrice)}).'
            : 'Fires alert as soon as price falls -${diffPercent.abs().toStringAsFixed(2)}% from live price (${FormatUtils.formatCurrency(currentPrice)}).');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppStyles.radius12),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.40 : 0.30),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isNeutral
                  ? Icons.info_outline_rounded
                  : (isBull
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded),
              size: 16,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    double percentDelta,
    double livePrice, {
    required bool isBull,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = isBull ? AppColors.bullGreen : AppColors.bearRed;

    return Expanded(
      child: GestureDetector(
        onTap: () => _applyPercentageDelta(percentDelta, livePrice),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(AppStyles.radius8),
            border: Border.all(
              color: chipColor.withValues(alpha: 0.25),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class TextInputKeyboards {
  static const TextInputType numberWithOptions =
      TextInputType.numberWithOptions(decimal: true);
}
