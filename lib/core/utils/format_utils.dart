/// Utility class for currency and date formatting without third-party dependencies.
class FormatUtils {
  FormatUtils._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Formats a double into standard comma-separated USD currency: e.g. "$100,000.00"
  static String formatCurrency(double val) {
    final isNegative = val < 0;
    final absVal = val.abs();
    final parts = absVal.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final sign = isNegative ? '-' : '';
    return '$sign\$$integerPart.${parts[1]}';
  }

  /// Formats a DateTime into e.g. "Oct 18, 02:45 PM"
  static String formatDate(DateTime dt) {
    final month = _months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $hour:$minute $period';
  }

  /// Formats a DateTime into e.g. "Oct 18, 2026 · 02:45:10 PM"
  static String formatDateTime(DateTime dt) {
    final month = _months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year · $hour:$minute:$second $period';
  }
}
