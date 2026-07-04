import 'package:flutter/material.dart';

class ScanQRPage extends StatelessWidget {
  const ScanQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Scan QR Code'), backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 4), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.qr_code_2, size: 200, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('Arahkan kamera ke QR Code', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('QR Code tersedia di meja atau stand kantin', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Simulasi Scan QR'),
            )
          ],
        ),
      ),
    );
  }
}