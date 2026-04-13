class EnvironmentModel {
  final String id;
  final DateTime timestamp;
  final double temperature;  // °C ambient
  final double humidity;     // %

  EnvironmentModel({required this.id, required this.timestamp,
    required this.temperature, required this.humidity});

  factory EnvironmentModel.fromMap(String id, Map<String, dynamic> map) {
    return EnvironmentModel(
      id: id,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      temperature: (map['temperature'] ?? 0).toDouble(),
      humidity: (map['humidity'] ?? 0).toDouble(),
    );
  }
}