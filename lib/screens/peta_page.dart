import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../models/canteen_model.dart';
import '../services/api_service.dart';

class PetaPage extends StatefulWidget {
  const PetaPage({super.key});

  @override
  State<PetaPage> createState() => _PetaPageState();
}

class _PetaPageState extends State<PetaPage> {
  String _activeFilter = 'Semua';
  final ApiService _apiService = ApiService();
  late Future<List<CanteenModel>> _canteensFuture;
  final MapController _mapController = MapController();

  // Titik pusat Politeknik Negeri Semarang
  static const LatLng _campusCenter = LatLng(-6.9825, 110.4092);
  static const double _defaultZoom = 17.0;

  // Koordinat hardcoded untuk kantin di area Polines
  // Akan digunakan sebagai fallback jika DB belum punya lat/lng
  static final Map<int, LatLng> _fallbackCoordinates = {
    0: const LatLng(-6.9820, 110.4085),
    1: const LatLng(-6.9830, 110.4098),
    2: const LatLng(-6.9818, 110.4100),
    3: const LatLng(-6.9835, 110.4080),
    4: const LatLng(-6.9825, 110.4110),
    5: const LatLng(-6.9815, 110.4075),
    6: const LatLng(-6.9840, 110.4095),
    7: const LatLng(-6.9822, 110.4068),
  };

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
      case 'Sepi':
        return const Color(0xFF22C55E);
      case 'Ramai':
        return const Color(0xFFF59E0B);
      case 'Padat':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Sepi':
        return Icons.check_circle;
      case 'Ramai':
        return Icons.warning_rounded;
      case 'Padat':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Sepi':
        return 'Sepi — Tersedia';
      case 'Ramai':
        return 'Ramai — Agak Penuh';
      case 'Padat':
        return 'Padat — Sangat Penuh';
      default:
        return status;
    }
  }

  LatLng _getCanteenPosition(CanteenModel canteen, int index) {
    // Jika DB sudah punya koordinat valid, gunakan itu
    if (canteen.latitude != 0.0 && canteen.longitude != 0.0) {
      return LatLng(canteen.latitude, canteen.longitude);
    }
    // Fallback ke koordinat hardcoded
    return _fallbackCoordinates[index % _fallbackCoordinates.length]!;
  }

  void _showCanteenInfo(BuildContext context, CanteenModel canteen) {
    final statusColor = _getStatusColor(canteen.status);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Nama kantin
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Color(0xFF1E3A8A),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canteen.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(canteen.status),
                            color: statusColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusLabel(canteen.status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Info row
            Row(
              children: [
                _buildInfoChip(Icons.access_time, canteen.timeEstimate.isNotEmpty ? canteen.timeEstimate : '~5 menit'),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.place, canteen.distance.isNotEmpty ? canteen.distance : '~100m'),
              ],
            ),
            const SizedBox(height: 20),
            // Tombol lihat detail
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/kantin', arguments: canteen);
                },
                child: const Text(
                  'Lihat Menu & Pesan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(List<CanteenModel> canteens) {
    final filtered = _activeFilter == 'Semua'
        ? canteens
        : canteens.where((c) => c.status == _activeFilter).toList();

    return List.generate(filtered.length, (i) {
      final canteen = filtered[i];
      // Cari index asli di list penuh untuk mapping koordinat
      final originalIndex = canteens.indexOf(canteen);
      final position = _getCanteenPosition(canteen, originalIndex);
      final color = _getStatusColor(canteen.status);

      return Marker(
        point: position,
        width: 48,
        height: 56,
        child: GestureDetector(
          onTap: () => _showCanteenInfo(context, canteen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              // Triangle pointer
              CustomPaint(
                size: const Size(12, 8),
                painter: _TrianglePainter(color: color),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Peta
          FutureBuilder<List<CanteenModel>>(
            future: _canteensFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                      SizedBox(height: 16),
                      Text(
                        'Memuat peta kampus...',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal memuat data kantin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshCanteens,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final canteens = snapshot.data ?? [];
              final markers = _buildMarkers(canteens);

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _campusCenter,
                  initialZoom: _defaultZoom,
                  maxZoom: 19.0,
                  minZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.eat_in_loc',
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),

          // Header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 12,
                20,
                16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1E3A8A).withValues(alpha: 0.95),
                    const Color(0xFF1E3A8A).withValues(alpha: 0.0),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Peta Kampus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Politeknik Negeri Semarang',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter chips overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Semua', 'Sepi', 'Ramai', 'Padat'].map((filter) {
                  final isSelected = _activeFilter == filter;
                  Color chipColor;
                  switch (filter) {
                    case 'Sepi':
                      chipColor = const Color(0xFF22C55E);
                      break;
                    case 'Ramai':
                      chipColor = const Color(0xFFF59E0B);
                      break;
                    case 'Padat':
                      chipColor = const Color(0xFFEF4444);
                      break;
                    default:
                      chipColor = const Color(0xFF1E3A8A);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _activeFilter = filter),
                      backgroundColor: Colors.white,
                      selectedColor: chipColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      elevation: 2,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? chipColor : Colors.grey[300]!,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Legend overlay (bottom-left)
          Positioned(
            bottom: 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Keterangan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildLegendItem(const Color(0xFF22C55E), 'Sepi'),
                  const SizedBox(height: 4),
                  _buildLegendItem(const Color(0xFFF59E0B), 'Ramai'),
                  const SizedBox(height: 4),
                  _buildLegendItem(const Color(0xFFEF4444), 'Padat'),
                ],
              ),
            ),
          ),

          // Re-center button (bottom-right)
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E3A8A),
              elevation: 4,
              onPressed: () {
                _mapController.move(_campusCenter, _defaultZoom);
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

// Custom painter untuk segitiga pointer di bawah marker
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}