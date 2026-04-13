class LocationModel {
  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromMap(Map<String, dynamic> data){
    return LocationModel(
      id: data['id'] ?? '',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
    );
  }


  
}
