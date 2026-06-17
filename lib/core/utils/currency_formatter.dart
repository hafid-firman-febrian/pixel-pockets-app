import 'package:intl/intl.dart';

/// Rupiah formatting helpers.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  /// `75000` -> `Rp 75.000`.
  static String format(num amount) => _rupiah.format(amount);

  /// Adds a leading sign: income `+Rp 8.000.000`, expense `-Rp 75.000`.
  static String formatSigned(num amount, {required bool isIncome}) {
    final sign = isIncome ? '+' : '-';
    return '$sign${format(amount.abs())}';
  }

  /// `8000000` -> `Rp 8,0 jt`. Useful for chart axes / tight spaces.
  static String compact(num amount) => _compact.format(amount);
}
