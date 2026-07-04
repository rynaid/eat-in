import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class StatusPesananScreen extends StatefulWidget {
  const StatusPesananScreen({super.key});

  @override
  State<StatusPesananScreen> createState() => _StatusPesananScreenState();
}

class _StatusPesananScreenState extends State<StatusPesananScreen> {
  final ApiService _apiService = ApiService();
  OrderModel? _order;
  bool _isLoading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final orderId = ModalRoute.of(context)?.settings.arguments as String?;
      if (orderId != null) {
        _loadOrder(orderId);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadOrder(String orderId) async {
    final order = await _apiService.fetchOrder(orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Status Pesanan'),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final order = _order;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Status Pesanan'),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Data pesanan tidak ditemukan.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Tentukan status langkah-langkah berdasarkan order_status
    bool step2Done = order.orderStatus == 'Dimasak' ||
        order.orderStatus == 'Siap' ||
        order.orderStatus == 'Done';
    bool step3Done = order.orderStatus == 'Siap' || order.orderStatus == 'Done';

    Color statusColor;
    String statusMessage;
    switch (order.orderStatus) {
      case 'Pending':
        statusColor = Colors.orange;
        statusMessage = 'Menunggu konfirmasi...';
        break;
      case 'Dimasak':
        statusColor = Colors.blue;
        statusMessage = 'Pesananmu sedang dimasak!';
        break;
      case 'Siap':
        statusColor = Colors.green;
        statusMessage = 'Silahkan ambil pesananmu!';
        break;
      case 'Done':
        statusColor = Colors.green;
        statusMessage = 'Pesanan selesai!';
        break;
      default:
        statusColor = Colors.grey;
        statusMessage = 'Memproses...';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Pesanan'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Status Pesanan',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    order.orderStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    order.canteenName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.formattedTotal,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(statusMessage,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  _buildProgressStep(
                      'Pesanan Diterima',
                      'Selesai',
                      true),
                  _buildProgressStep(
                      'Sedang Dimasak',
                      step2Done ? 'Selesai' : 'Menunggu',
                      step2Done),
                  _buildProgressStep(
                      'Siap Diambil',
                      step3Done ? 'Ambil pesananmu' : 'Menunggu',
                      step3Done),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/main',
              (route) => false,
              arguments: 2,
            );
          },
          child: const Text(
            'Kembali ke Menu Utama / Riwayat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(String title, String subtitle, bool isDone) {
    return ListTile(
      leading: Icon(
        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isDone ? Colors.green : Colors.grey,
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDone ? Colors.black : Colors.grey)),
      subtitle: Text(subtitle),
    );
  }
}