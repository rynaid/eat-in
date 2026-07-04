class MenuModel {
  final String id;
  final String canteenId;
  final String name;
  final int price;
  final String type;

  MenuModel({
    required this.id,
    required this.canteenId,
    required this.name,
    required this.price,
    required this.type,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    // Parsing price secara aman untuk mencegah _TypeError di masa depan
    final rawPrice = json['price'];
    int parsedPrice = 0;
    if (rawPrice is num) {
      parsedPrice = rawPrice.toInt();
    } else if (rawPrice is String) {
      parsedPrice = int.tryParse(rawPrice) ?? 0;
    }

    // Jika kolom 'type' tidak ada di database, kita deteksi otomatis dari nama menu
    // agar tab filter (Makanan / Minuman) di UI tetap berfungsi dengan baik.
    String parsedType = json['type'] ?? '';
    if (parsedType.isEmpty) {
      final nameLower = (json['name'] ?? '').toString().toLowerCase();
      if (nameLower.contains('es') ||
          nameLower.contains('teh') ||
          nameLower.contains('jus') ||
          nameLower.contains('air') ||
          nameLower.contains('kopi') ||
          nameLower.contains('minum') ||
          nameLower.contains('soda') ||
          nameLower.contains('juice') ||
          nameLower.contains('tea')) {
        parsedType = 'minuman';
      } else {
        parsedType = 'makanan';
      }
    }

    return MenuModel(
      id: json['id'] ?? '',
      canteenId: json['canteen_id'] ?? '',
      name: json['name'] ?? '',
      price: parsedPrice,
      type: parsedType,
    );
  }

  // Helper untuk format harga ke Rupiah (cth: Rp 15.000)
  String get formattedPrice {
    final String priceStr = price.toString();
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
