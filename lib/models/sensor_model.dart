class SensorModel {
  final int sensorNumber; // 1-6
  final double value;
  final String unit;
  final String status; // 'online', 'offline', 'error'
  final DateTime timestamp;
  final String? label; // e.g., 'Temperature', 'Humidity', etc.

  SensorModel({
    required this.sensorNumber,
    required this.value,
    required this.unit,
    required this.status,
    required this.timestamp,
    this.label,
  });

  factory SensorModel.fromMap(int sensorNum, Map<String, dynamic> map) {
    return SensorModel(
      sensorNumber: sensorNum,
      value: (map['value'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'unknown',
      status: map['status'] ?? 'offline',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      label: map['label'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sensorNumber': sensorNumber,
      'value': value,
      'unit': unit,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (label != null) 'label': label,
    };
  }

  @override
  String toString() => 'Sensor#$sensorNumber: $value $unit ($status)';
}
