import '../utils/format_utils.dart';

class OrderModel {
  final String id;
  final String canteenName;
  final int totalPayment;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.canteenName,
    required this.totalPayment,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parsing total_payment secara aman untuk mencegah TypeError
    final rawTotal = json['total_payment'];
    int parsedTotal = 0;
    if (rawTotal is num) {
      parsedTotal = rawTotal.toInt();
    } else if (rawTotal is String) {
      parsedTotal = int.tryParse(rawTotal) ?? 0;
    }

    // Nama kantin dari relasi join: select('*, canteens(name)')
    String canteenName = '';
    if (json['canteens'] is Map) {
      canteenName = json['canteens']['name'] ?? '';
    }

    return OrderModel(
      id: json['id'] ?? '',
      canteenName: canteenName,
      totalPayment: parsedTotal,
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? 'Unpaid',
      orderStatus: json['order_status'] ?? 'Pending',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedTotal => FormatUtils.formatRupiah(totalPayment);

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
