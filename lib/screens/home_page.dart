import 'package:flutter/material.dart';
import '../models/canteen_model.dart';
import '../services/api_service.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _activeFilter = 'Semua';
  final ApiService _apiService = ApiService();
  late Future<List<CanteenModel>> _canteensFuture;

  @override
  void initState() {
    super.initState();
    _canteensFuture = _apiService.fetchCanteens();
  }

  void _refreshCanteens() {
    setState(() {
      _canteensFuture = _apiService.fetchCanteens();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sepi': return Colors.green;
      case 'Ramai': return Colors.orange;
      case 'Padat': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilterRow(),
          Expanded(
            child: FutureBuilder<List<CanteenModel>>(
              future: _canteensFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshCanteens,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.hasData) {
                  List<CanteenModel> canteens = snapshot.data!;
                  if (_activeFilter != 'Semua') {
                    canteens = canteens.where((c) => c.status == _activeFilter).toList();
                  }

                  if (canteens.isEmpty) {
                    return const Center(child: Text('Tidak ada kantin dengan status ini.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: canteens.length,
                    itemBuilder: (context, index) {
                      final item = canteens[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(width: 60, height: 60, color: Colors.blue[50]),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(color: _getStatusColor(item.status), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(item.status, style: TextStyle(color: _getStatusColor(item.status), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${item.timeEstimate} • ${item.distance}'),
                            ],
                          ),
                          onTap: () => Navigator.pushNamed(context, '/kantin', arguments: item),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text('Data kosong'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      color: const Color(0xFF1E3A8A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Selamat datang 😊', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('Eat In Loc', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari menu atau kantin...',
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    List<String> filters = ['Semua', 'Sepi', 'Ramai', 'Padat'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: filters.map((f) {
          bool isSelected = _activeFilter == f;
          return ChoiceChip(
            label: Text(f),
            selected: isSelected,
            selectedColor: const Color(0xFF1E3A8A),
            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
            onSelected: (val) => setState(() => _activeFilter = f),
          );
        }).toList(),
      ),
    );
  }
}