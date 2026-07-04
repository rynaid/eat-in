import 'package:flutter/material.dart';
import '../models/canteen_model.dart';
import '../models/menu_model.dart';
import '../models/cart_item_model.dart';
import '../services/api_service.dart';
import '../utils/format_utils.dart';

class KantinDetailScreen extends StatefulWidget {
  const KantinDetailScreen({super.key});

  @override
  State<KantinDetailScreen> createState() => _KantinDetailScreenState();
}

class _KantinDetailScreenState extends State<KantinDetailScreen> {
  final ApiService _apiService = ApiService();
  CanteenModel? _canteen;
  bool _hasLoggedActivity = false;
  final Map<String, CartItemModel> _cartItems = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ambil arguments dengan null safety
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is CanteenModel) {
      _canteen = args;

      // Log aktivitas hanya sekali, bukan setiap rebuild
      if (!_hasLoggedActivity) {
        _hasLoggedActivity = true;
        _apiService.logActivity(
          'Melihat Detail Kantin',
          'User membuka halaman detail untuk ${_canteen!.name}',
        );
      }
    }
  }

  void _addToCart(MenuModel menu) {
    setState(() {
      if (_cartItems.containsKey(menu.id)) {
        _cartItems[menu.id]!.quantity++;
      } else {
        _cartItems[menu.id] = CartItemModel(menu: menu);
      }
    });
  }

  void _removeFromCart(MenuModel menu) {
    setState(() {
      if (_cartItems.containsKey(menu.id)) {
        if (_cartItems[menu.id]!.quantity > 1) {
          _cartItems[menu.id]!.quantity--;
        } else {
          _cartItems.remove(menu.id);
        }
      }
    });
  }

  int get _totalItems => _cartItems.values.fold(0, (sum, item) => sum + item.quantity);
  int get _totalPrice => _cartItems.values.fold(0, (sum, item) => sum + item.subtotal);

  @override
  Widget build(BuildContext context) {
    final canteen = _canteen;

    // Jika arguments tidak valid, tampilkan error screen
    if (canteen == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Data kantin tidak ditemukan.\nSilakan kembali dan coba lagi.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(canteen.name),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [Tab(text: 'Semua'), Tab(text: 'Makanan'), Tab(text: 'Minuman')],
            labelColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            MenuList(
              canteenId: canteen.id,
              filter: 'semua',
              cartItems: _cartItems,
              onAddToCart: _addToCart,
              onRemoveFromCart: _removeFromCart,
            ),
            MenuList(
              canteenId: canteen.id,
              filter: 'makanan',
              cartItems: _cartItems,
              onAddToCart: _addToCart,
              onRemoveFromCart: _removeFromCart,
            ),
            MenuList(
              canteenId: canteen.id,
              filter: 'minuman',
              cartItems: _cartItems,
              onAddToCart: _addToCart,
              onRemoveFromCart: _removeFromCart,
            ),
          ],
        ),
        // Tampilkan bar keranjang jika ada item di cart
        bottomNavigationBar: _cartItems.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/keranjang', arguments: {
                      'canteen': canteen,
                      'cartItems': _cartItems.values.toList(),
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lihat Keranjang ($_totalItems item)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        FormatUtils.formatRupiah(_totalPrice),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class MenuList extends StatefulWidget {
  final String canteenId;
  final String filter;
  final Map<String, CartItemModel> cartItems;
  final Function(MenuModel) onAddToCart;
  final Function(MenuModel) onRemoveFromCart;

  const MenuList({
    super.key,
    required this.canteenId,
    required this.filter,
    required this.cartItems,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  @override
  State<MenuList> createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
  final ApiService _apiService = ApiService();
  late Future<List<MenuModel>> _menuFuture;

  @override
  void initState() {
    super.initState();
    _menuFuture = _apiService.fetchMenusByCanteen(widget.canteenId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MenuModel>>(
      future: _menuFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Menu belum tersedia'));
        }

        final allItems = snapshot.data!;
        final filtered = widget.filter == 'semua'
            ? allItems
            : allItems.where((i) => i.type == widget.filter).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('Kategori kosong'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final menu = filtered[index];
            final cartItem = widget.cartItems[menu.id];
            final qty = cartItem?.quantity ?? 0;

            return Card(
              child: ListTile(
                title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(menu.formattedPrice),
                trailing: qty > 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => widget.onRemoveFromCart(menu),
                          ),
                          Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF1E3A8A)),
                            onPressed: () => widget.onAddToCart(menu),
                          ),
                        ],
                      )
                    : IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF1E3A8A)),
                        onPressed: () => widget.onAddToCart(menu),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}