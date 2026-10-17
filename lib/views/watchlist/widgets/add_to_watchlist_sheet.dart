import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/watchlist/watchlist_bloc.dart';
import '../../../blocs/watchlist/watchlist_event.dart';
import '../../../blocs/watchlist/watchlist_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../models/instrument_model.dart';
import 'create_watchlist_dialog.dart';

/// Bottom sheet allowing users to add/remove an instrument across their custom watchlists.
class AddToWatchlistSheet extends StatelessWidget {
  const AddToWatchlistSheet({
    super.key,
    required this.instrument,
  });

  final InstrumentModel instrument;

  static Future<void> show({
    required BuildContext context,
    required InstrumentModel instrument,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: 'Save ${instrument.symbol}',
      child: AddToWatchlistSheet(instrument: instrument),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocBuilder<WatchlistBloc, WatchlistState>(
      builder: (context, state) {
        if (state is! WatchlistsLoaded) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final watchlists = state.watchlists;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Equity Subheader
            Text(
              'Select collections to track ${instrument.name} (${instrument.symbol}).',
              style: TextStyle(
                fontSize: 12.5,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Watchlists List with Checkboxes
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: watchlists.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor.withValues(alpha: 0.6),
                ),
                itemBuilder: (context, index) {
                  final list = watchlists[index];
                  final isChecked = list.symbols.contains(instrument.symbol.toUpperCase());

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      AppHaptics.selection();
                      context.read<WatchlistBloc>().add(
                            WatchlistSymbolToggled(
                              watchlistId: list.id,
                              symbol: instrument.symbol,
                            ),
                          );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            isChecked
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isChecked ? AppColors.primaryBlue : textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  list.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  '${list.symbols.length} items',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (list.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRIMARY',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Action: Create New Watchlist
            OutlinedButton.icon(
              onPressed: () {
                AppHaptics.light();
                CreateWatchlistDialog.show(
                  context: context,
                  onConfirm: (name) {
                    context.read<WatchlistBloc>().add(WatchlistCreated(name: name));
                  },
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create New Watchlist'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
