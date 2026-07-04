class CanteenModel {
  final String id;
  final String name;
  final String status;
  final String timeEstimate;
  final String distance;
  final double latitude;
  final double longitude;

  CanteenModel({
    required this.id,
    required this.name,
    required this.status,
    required this.timeEstimate,
    required this.distance,
    required this.latitude,
    required this.longitude,
  });

  factory CanteenModel.fromJson(Map<String, dynamic> json) {
    return CanteenModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'Sepi',
      timeEstimate: json['time_estimate'] ?? '',
      distance: json['distance'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}