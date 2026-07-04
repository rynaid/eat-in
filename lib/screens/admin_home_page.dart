import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';
import '../models/menu_model.dart';
import '../models/canteen_model.dart';
import '../utils/format_utils.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  bool _isLoading = true;
  String _canteenId = '';
  String _canteenName = 'Kantin';
  CanteenModel? _currentCanteen;
  
  List<OrderModel> _orders = [];
  List<MenuModel> _menus = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final roleData = await _apiService.getUserRoleAndCanteen(user.id, user.email ?? '');
      _canteenId = roleData['canteen_id'] ?? '';
      
      if (_canteenId.isNotEmpty) {
        // Ambil data kantin spesifik
        try {
          final canteens = await _apiService.fetchCanteens();
          final myCanteen = canteens.firstWhere((c) => c.id == _canteenId);
          _currentCanteen = myCanteen;
          _canteenName = myCanteen.name;
        } catch (e) {
          debugPrint('Gagal mencocokkan ID kantin: $e');
        }
        
        // Load data pesanan dan menu
        await Future.wait([
          _refreshOrders(),
          _refreshMenus(),
        ]);
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshOrders() async {
    if (_canteenId.isEmpty) return;
    final orders = await _apiService.fetchOrdersByCanteen(_canteenId);
    if (mounted) {
      setState(() {
        _orders = orders;
      });
    }
  }

  Future<void> _refreshMenus() async {
    if (_canteenId.isEmpty) return;
    final menus = await _apiService.fetchMenusByCanteen(_canteenId);
    if (mounted) {
      setState(() {
        _menus = menus;
      });
    }
  }

  Future<void> _updateCanteenStatus(String status) async {
    if (_canteenId.isEmpty) return;
    setState(() => _isLoading = true);
    final success = await _apiService.updateCanteenStatus(_canteenId, status);
    if (success) {
      await _loadAdminData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status kantin diubah menjadi $status')),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status kantin')),
        );
      }
    }
  }

  Future<void> _changeOrderStatus(String orderId, String newStatus, {String? paymentStatus}) async {
    final success = await _apiService.updateOrderStatus(orderId, newStatus, paymentStatus: paymentStatus);
    if (success) {
      await _refreshOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesanan berhasil diubah ke: $newStatus')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status pesanan')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_canteenId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Kantin'),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.store_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Kantin Belum Terhubung',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Akun admin Anda belum dikaitkan dengan kantin mana pun di database Supabase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadAdminData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                  ),
                  child: const Text('Muat Ulang', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_canteenName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Admin Dashboard • ${_currentCanteen?.status ?? 'Aktif'}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Pesanan'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
            Tab(icon: Icon(Icons.settings), text: 'Pengaturan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          _buildMenuTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  // ================= TAB PESANAN =================
  Widget _buildOrdersTab() {
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: _orders.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 150),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada pesanan masuk', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return _buildOrderCard(order);
              },
            ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusColor;
    switch (order.orderStatus) {
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Dimasak':
        statusColor = Colors.blue;
        break;
      case 'Siap':
        statusColor = Colors.green;
        break;
      case 'Done':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order #${order.id.substring(0, 5).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.orderStatus,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${order.formattedDate} • ${order.paymentMethod} (${order.paymentStatus})',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Fetch dan Tampilkan Item Pesanan
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _apiService.fetchOrderItems(order.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Text('Gagal memuat item pesanan');
              }
              return Column(
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item['menu_name']} x${item['quantity']}'),
                        Text(FormatUtils.formatRupiah(item['price_at_time'] * (item['quantity'] as int))),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(order.formattedTotal, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            ],
          ),
          const SizedBox(height: 16),
          // Tombol Tindakan Berdasarkan Status
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (order.orderStatus == 'Pending')
                ElevatedButton.icon(
                  onPressed: () => _changeOrderStatus(order.id, 'Dimasak'),
                  icon: const Icon(Icons.cookie, color: Colors.white),
                  label: const Text('Terima & Masak', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              if (order.orderStatus == 'Dimasak')
                ElevatedButton.icon(
                  onPressed: () => _changeOrderStatus(order.id, 'Siap'),
                  icon: const Icon(Icons.notifications_active, color: Colors.white),
                  label: const Text('Siap Diambil', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              if (order.orderStatus == 'Siap')
                ElevatedButton.icon(
                  onPressed: () => _changeOrderStatus(order.id, 'Done', paymentStatus: 'Paid'),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Selesai / Diambil', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              if (order.orderStatus == 'Done')
                const Text(
                  'Transaksi Selesai ✅',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
            ],
          )
        ],
      ),
    );
  }

  // ================= TAB MENU =================
  Widget _buildMenuTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A8A),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showMenuFormDialog(),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMenus,
        child: _menus.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 150),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_menu_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Belum ada menu terdaftar', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _menus.length,
                itemBuilder: (context, index) {
                  final menu = _menus[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: menu.type == 'minuman' ? Colors.blue[50] : Colors.orange[50],
                        child: Icon(
                          menu.type == 'minuman' ? Icons.local_drink : Icons.restaurant,
                          color: menu.type == 'minuman' ? Colors.blue : Colors.orange,
                        ),
                      ),
                      title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(menu.formattedPrice),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () => _showMenuFormDialog(menu: menu),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDeleteMenu(menu.id, menu.name),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showMenuFormDialog({MenuModel? menu}) {
    final isEdit = menu != null;
    final nameController = TextEditingController(text: isEdit ? menu.name : '');
    final priceController = TextEditingController(text: isEdit ? menu.price.toString() : '');
    String selectedType = isEdit ? menu.type : 'makanan';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Ubah Menu Makanan' : 'Tambah Menu Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Menu'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Makanan', style: TextStyle(fontSize: 12)),
                            value: 'makanan',
                            groupValue: selectedType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setDialogState(() => selectedType = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Minuman', style: TextStyle(fontSize: 12)),
                            value: 'minuman',
                            groupValue: selectedType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setDialogState(() => selectedType = val!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final price = int.tryParse(priceController.text.trim()) ?? 0;
                    if (name.isEmpty || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Form tidak valid!')),
                      );
                      return;
                    }
                    
                    Navigator.pop(context);
                    setState(() => _isLoading = true);

                    bool success;
                    if (isEdit) {
                      success = await _apiService.updateMenuItem(menu.id, name, price, selectedType);
                    } else {
                      success = await _apiService.addMenuItem(_canteenId, name, price, selectedType);
                    }

                    if (success) {
                      await _refreshMenus();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Menu berhasil ${isEdit ? "diubah" : "ditambahkan"}!')),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gagal menyimpan menu')),
                        );
                      }
                    }
                    setState(() => _isLoading = false);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteMenu(String menuId, String menuName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Menu'),
          content: Text('Apakah Anda yakin ingin menghapus menu "$menuName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                final success = await _apiService.deleteMenuItem(menuId);
                if (success) {
                  await _refreshMenus();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menu berhasil dihapus')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal menghapus menu')),
                    );
                  }
                }
                setState(() => _isLoading = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ================= TAB PENGATURAN =================
  Widget _buildSettingsTab() {
    final user = Supabase.instance.client.auth.currentUser;
    final currentStatus = _currentCanteen?.status ?? 'Sepi';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil Kantin Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    child: const Icon(Icons.store, size: 36, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _canteenName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          const Text('Status Kesibukan Kantin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Sesuaikan status kesibukan kantin saat ini agar mahasiswa dapat melihat kondisi antrean secara real-time.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          
          // Row untuk Pilihan Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusButton('Sepi', Colors.green, currentStatus == 'Sepi'),
              _buildStatusButton('Sedang', Colors.orange, currentStatus == 'Sedang'),
              _buildStatusButton('Ramai', Colors.red, currentStatus == 'Ramai'),
              _buildStatusButton('Tutup', Colors.grey, currentStatus == 'Tutup'),
            ],
          ),
          
          const SizedBox(height: 48),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Keluar dari Akun', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String status, Color color, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            _updateCanteenStatus(status);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            border: Border.all(color: color, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              status,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
