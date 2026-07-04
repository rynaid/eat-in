import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/canteen_model.dart';
import '../models/cart_item_model.dart';
import '../services/api_service.dart';
import '../utils/format_utils.dart';

class KeranjangPesananScreen extends StatefulWidget {
  const KeranjangPesananScreen({super.key});

  @override
  State<KeranjangPesananScreen> createState() => _KeranjangPesananScreenState();
}

class _KeranjangPesananScreenState extends State<KeranjangPesananScreen> {
  String _paymentMethod = 'QR';
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<CartItemModel> _cartItems = [];
  CanteenModel? _canteen;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _canteen = args['canteen'] as CanteenModel?;
        final rawItems = args['cartItems'];
        if (rawItems is List<CartItemModel>) {
          _cartItems = List<CartItemModel>.from(rawItems);
        }
      }
    }
  }

  int get _totalPrice => _cartItems.fold(0, (sum, item) => sum + item.subtotal);

  void _prosesCheckout() async {
    final canteen = _canteen;
    if (canteen == null || _cartItems.isEmpty) return;

    setState(() => _isLoading = true);

    // Ambil ID user dari sesi auth yang sedang login
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda belum login!')),
      );
      return;
    }

    // Payload untuk tabel 'orders'
    Map<String, dynamic> orderData = {
      "user_id": userId,
      "canteen_id": canteen.id,
      "total_payment": _totalPrice,
      "payment_method": _paymentMethod,
    };

    // Payload untuk tabel 'order_items' — dari keranjang nyata
    List<Map<String, dynamic>> orderItems = _cartItems.map((item) => {
      "menu_id": item.menu.id,
      "quantity": item.quantity,
      "price_at_time": item.menu.price,
    }).toList();

    // Panggil ApiService — sekarang mengembalikan orderId
    final orderId = await _apiService.createOrder(orderData, orderItems);

    setState(() => _isLoading = false);

    if (orderId != null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/status', arguments: orderId);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pesanan ke server!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_canteen == null || _cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Keranjang Pesanan'),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Keranjang kosong.\nSilakan pilih menu terlebih dahulu.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Pesanan'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KANTIN: ${_canteen!.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 16),
                  const Text('ITEM DIPILIH', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ...List.generate(_cartItems.length, (index) {
                    final item = _cartItems[index];
                    return ListTile(
                      title: Text(item.menu.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item.menu.formattedPrice),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                if (item.quantity > 1) {
                                  item.quantity--;
                                } else {
                                  _cartItems.removeAt(index);
                                }
                              });
                            },
                          ),
                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => item.quantity++),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  const Text('RINGKASAN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ..._cartItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.quantity}x ${item.menu.name}'),
                        Text(item.formattedSubtotal),
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        FormatUtils.formatRupiah(_totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('METODE PEMBAYARAN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Scan QR')),
                          selected: _paymentMethod == 'QR',
                          onSelected: (val) => setState(() => _paymentMethod = 'QR'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Tunai')),
                          selected: _paymentMethod == 'Tunai',
                          onSelected: (val) => setState(() => _paymentMethod = 'Tunai'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
      bottomNavigationBar: _cartItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _paymentMethod == 'QR' ? const Color(0xFF1E3A8A) : Colors.green,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _prosesCheckout,
                child: Text(
                  _paymentMethod == 'QR'
                      ? 'Bayar via Scan QR • ${FormatUtils.formatRupiah(_totalPrice)}'
                      : 'Pesan & Bayar Tunai • ${FormatUtils.formatRupiah(_totalPrice)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }
}