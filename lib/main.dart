import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_onboarding.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/main_navigation.dart';
import 'screens/kantin_detail_page.dart';
import 'screens/keranjang_pesanan_page.dart';
import 'screens/status_pesanan_page.dart';
import 'screens/admin_home_page.dart';

void main() async {
  // Wajib untuk inisialisasi asynchronous native plugin
  WidgetsFlutterBinding.ensureInitialized();

  // Koneksi ke project Supabase Cloud milikmu
  await Supabase.initialize(
    url: 'https://libsdapswyxiwztgohza.supabase.co',
    publishableKey: 'sb_publishable_ZAss8BIuUTuTM7eicqB_2w_LcoQcdDj',
  );

  runApp(const EatInLocApp());
}

class EatInLocApp extends StatelessWidget {
  const EatInLocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eat In Loc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3A8A),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => const MainNavigationWrapper(),
        '/kantin': (context) => const KantinDetailScreen(),
        '/keranjang': (context) => const KeranjangPesananScreen(),
        '/status': (context) => const StatusPesananScreen(),
        '/admin_home': (context) => const AdminHomePage(),
      },
    );
  }
}