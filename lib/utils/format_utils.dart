class FormatUtils {
  /// Format angka menjadi format Rupiah (cth: 15000 → Rp 15.000)
  static String formatRupiah(int amount) {
    final String priceStr = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < priceStr.length; i++) {
      if (i > 0 && (priceStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(priceStr[i]);
    }
    return 'Rp ${buffer.toString()}';
  }
}
