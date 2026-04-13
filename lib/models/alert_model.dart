class AlertModel {
  final String id;
  final DateTime timestamp;
  final String type;    
  final String level;    // 'low', 'medium', 'high'
  final String message;
  final String status;   

  AlertModel({required this.id, required this.timestamp, required this.type,
    required this.level, required this.message, required this.status});

  factory AlertModel.fromMap(String id, Map<String, dynamic> map) {
    return AlertModel(
      id: id,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      type: map['type'] ?? '',
      level: map['level'] ?? 'low',
      message: map['message'] ?? '',
      status: map['status'] ?? 'unread',
    );
  }
}