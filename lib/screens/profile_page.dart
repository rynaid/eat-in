import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  String _fullName = '';
  String _email = '';
  String _phoneNumber = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _email = user.email ?? '';
      final profile = await _apiService.fetchProfile(user.id);
      if (profile != null) {
        _fullName = profile['full_name'] ?? '';
        _phoneNumber = profile['phone_number'] ?? '';
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            _fullName.isNotEmpty
                                ? _fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fullName.isNotEmpty ? _fullName : 'Mahasiswa',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_email,
                            style: const TextStyle(color: Colors.grey)),
                        if (_phoneNumber.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_phoneNumber,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Tentang Aplikasi Ini',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                    'LOG IN LOC (Eat-in-Loc) adalah konsep aplikasi mobile berbasis lokasi yang dirancang untuk mentransformasi pengalaman kuliner mahasiswa di lingkungan kampus.\n\nAplikasi ini hadir sebagai solusi cerdas untuk mengatasi masalah antrean panjang, ketidakpastian stok menu, dan manajemen waktu istirahat mahasiswa yang terbatas.',
                    style: TextStyle(height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}