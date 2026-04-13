class VitalDataModel {
  final String id;
  final DateTime timestamp;
  final double heartRate;   // BPM
  final double spO2;        // %
  final double bodyTemp;    // °C

  VitalDataModel({required this.id, required this.timestamp,
    required this.heartRate, required this.spO2, required this.bodyTemp});

  factory VitalDataModel.fromMap(String id, Map<String, dynamic> map) {
    return VitalDataModel(
      id: id,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      heartRate: (map['heartRate'] ?? 0).toDouble(),
      spO2: (map['spO2'] ?? 0).toDouble(),
      bodyTemp: (map['bodyTemp'] ?? 0).toDouble(),
    );
  }
}