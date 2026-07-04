import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Kirim Log Buka Aplikasi
    await _apiService.logActivity(
      'Buka Aplikasi',
      'User berhasil masuk dan melewati Splash Screen.',
    );

    if (!mounted) return;

    // Cek apakah user sudah login
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final roleData = await _apiService.getUserRoleAndCanteen(user.id, user.email ?? '');
        if (!mounted) return;
        if (roleData['role'] == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_home');
          return;
        }
      } catch (e) {
        debugPrint('Gagal memeriksa role di Splash: $e');
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Eat In Loc',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  final ApiService _apiService = ApiService();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _onboardingData = [
    {'title': 'Temukan Kantin Favoritmu', 'subtitle': 'Lihat semua kantin kampus secara real-time.'},
    {'title': 'Bayar Lewat QR Code', 'subtitle': 'Scan QR untuk melakukan pembayaran cepat.'},
    {'title': 'Notifikasi Otomatis', 'subtitle': 'Dapatkan pemberitahuan saat makanan siap.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _apiService.logActivity(
                    'Geser Onboarding',
                    'User melihat slide ke-${index + 1}',
                  );
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _onboardingData[index]['title']!,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _onboardingData[index]['subtitle']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      _apiService.logActivity('Skip Onboarding', 'User melewati onboarding.');
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Skip', style: TextStyle(color: Colors.white70)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentIndex == _onboardingData.length - 1) {
                        _apiService.logActivity('Selesai Onboarding', 'User masuk ke halaman utama.');
                        Navigator.pushReplacementNamed(context, '/login');
                      } else {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    },
                    child: Text(_currentIndex == _onboardingData.length - 1 ? 'Start' : 'Next'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}