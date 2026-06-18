/// Utility formatting angka uang untuk Pixel Pocket.
///
/// Tidak membutuhkan package tambahan — murni Dart.
///
/// Contoh pemakaian:
/// ```dart
/// CurrencyFormatter.format(8000000)      // "Rp 8.000.000"
/// CurrencyFormatter.compact(8000000)     // "Rp 8 jt"
/// CurrencyFormatter.compact(1500000)     // "Rp 1,5 jt"
/// CurrencyFormatter.signed(75000, 'expense')  // "-Rp 75.000"
/// CurrencyFormatter.signed(8000000, 'income') // "+Rp 8.000.000"
/// CurrencyFormatter.input(8000000)       // "8.000.000"
/// CurrencyFormatter.parse("8.000.000")  // 8000000.0
/// ```
class CurrencyFormatter {
  CurrencyFormatter._();

  // ─────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────

  /// Format lengkap dengan prefix "Rp ".
  ///
  /// ```dart
  /// format(8000000)   // "Rp 8.000.000"
  /// format(75000)     // "Rp 75.000"
  /// format(500)       // "Rp 500"
  /// format(0)         // "Rp 0"
  /// ```
  static String format(double amount) {
    return 'Rp ${_thousands(amount.abs())}';
  }

  /// Format ringkas — ribuan = "rb", jutaan = "jt", miliaran = "M".
  ///
  /// ```dart
  /// compact(8000000)   // "Rp 8 jt"
  /// compact(1500000)   // "Rp 1,5 jt"
  /// compact(250000)    // "Rp 250 rb"
  /// compact(1500000000) // "Rp 1,5 M"
  /// compact(500)       // "Rp 500"
  /// ```
  static String compact(double amount) {
    final abs = amount.abs();

    if (abs >= 1000000000) {
      return 'Rp ${_trimDecimal(abs / 1000000000)} M';
    }
    if (abs >= 1000000) {
      return 'Rp ${_trimDecimal(abs / 1000000)} jt';
    }
    if (abs >= 1000) {
      return 'Rp ${_trimDecimal(abs / 1000)} rb';
    }
    return 'Rp ${abs.toStringAsFixed(0)}';
  }

  /// Format dengan tanda + / - berdasarkan tipe transaksi.
  ///
  /// ```dart
  /// signed(8000000, 'income')  // "+Rp 8.000.000"
  /// signed(75000,  'expense') // "-Rp 75.000"
  /// ```
  static String signed(double amount, String transactionType) {
    final prefix = transactionType == 'income' ? '+' : '-';
    return '$prefix${format(amount)}';
  }

  /// Format untuk input field — tanpa prefix "Rp", hanya angka + titik ribuan.
  ///
  /// ```dart
  /// input(8000000)  // "8.000.000"
  /// input(75000)    // "75.000"
  /// input(0)        // ""
  /// ```
  static String input(double amount) {
    if (amount == 0) return '';
    return _thousands(amount.abs());
  }

  /// Parse string dari input field kembali ke double.
  /// Menghapus semua titik, koma, "Rp", dan spasi.
  ///
  /// ```dart
  /// parse("8.000.000")  // 8000000.0
  /// parse("Rp 75.000")  // 75000.0
  /// parse("")           // 0.0
  /// parse("abc")        // 0.0
  /// ```
  static double parse(String value) {
    final cleaned = value
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Format saat user mengetik di input field.
  /// Input: string angka mentah (dari keyboard).
  /// Output: string dengan titik ribuan otomatis.
  ///
  /// Pakai ini di `onChanged` TextField.
  ///
  /// ```dart
  /// formatWhileTyping("8000")    // "8.000"
  /// formatWhileTyping("8000000") // "8.000.000"
  /// formatWhileTyping("")        // ""
  /// ```
  static String formatWhileTyping(String raw) {
    // Hapus semua karakter selain digit
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    final number = double.tryParse(digits) ?? 0;
    return _thousands(number);
  }

  // ─────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────

  /// Tambah titik setiap 3 digit dari kanan.
  ///
  /// ```dart
  /// _thousands(8000000)  // "8.000.000"
  /// _thousands(75000)    // "75.000"
  /// _thousands(500)      // "500"
  /// ```
  static String _thousands(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      buffer.write(str[i]);
      final remaining = length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  /// Tampilkan 1 desimal hanya jika bukan bilangan bulat.
  ///
  /// ```dart
  /// _trimDecimal(8.0)   // "8"
  /// _trimDecimal(1.5)   // "1,5"
  /// _trimDecimal(2.25)  // "2,3"
  /// ```
  static String _trimDecimal(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    // Ganti titik dengan koma — konvensi Indonesia
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}
