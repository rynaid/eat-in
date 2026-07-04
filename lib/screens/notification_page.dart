import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi'), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationCard('Pesanan Siap!', 'Pesananmu di Warung Bu Siti sudah siap diambil.', '2 menit'),
          _buildNotificationCard('Promo Hari Ini', 'Diskon 20% untuk semua menu minuman hingga jam 14.00.', '30 menit'),
          _buildNotificationCard('Antrian Meledak', 'Mie Ayam Mas Budi sekarang hanya 5 menit tunggu ya.', '3 jam'),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String title, String body, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.amber),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(body),
        trailing: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ),
    );
  }
}