class VitalDataModel {
  final String id;
  final DateTime timestamp;
  final double heartRate; // BPM
  final double spO2; // %
  final double bodyTemp; // °C
  final double respiratoryRate; // Placeholder for air quality index (AQI)
  final double systolicBP;
  final double diastolicBP;
  final String activity;

  VitalDataModel({
    required this.id,
    required this.timestamp,
    required this.heartRate,
    required this.spO2,
    required this.bodyTemp,
    required this.respiratoryRate,
    required this.systolicBP,
    required this.activity,
    required this.diastolicBP,
  });

  factory VitalDataModel.fromMap(String id, Map<String, dynamic> map) {
    return VitalDataModel(
      id: id,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      heartRate: (map['heartRate'] ?? 0).toDouble(),
      spO2: (map['spo2'] ?? 0).toDouble(),
      bodyTemp: (map['bodyTemp'] ?? 0).toDouble(),
      respiratoryRate: (map['respiratoryRate'] ?? 0).toDouble(),
      systolicBP: (map['systolicBP'] ?? 0).toDouble(),
      diastolicBP: (map['diastolicBP'] ?? 0).toDouble(),
      activity: (map['activity'] ?? 'unknown'),
    );
  }

  // HEATH DATUTS

  String get heartRateStatus {
    if (heartRate >= 60 && heartRate <= 100) return 'normal';
    if (heartRate > 100 && heartRate <= 120) return 'warning';
    if (heartRate < 60 && heartRate >= 50) return 'warning';
    return 'emergency'; // <50 or >120
  }

  String get spO2Status {
    if (spO2 >= 95) return 'normal';
    if (spO2 >= 90 && spO2 < 95) return 'warning';
    return 'emergency'; // <90
  }

  String get bodyTempStatus {
    if (bodyTemp >= 36.1 && bodyTemp <= 37.2) return 'normal';
    if ((bodyTemp > 37.2 && bodyTemp <= 38) ||
        (bodyTemp < 36.1 && bodyTemp >= 35)) {
      return 'warning';
    }
    return 'emergency'; // >38 or <35
  }

  String get respiratoryRateStatus {
    if (respiratoryRate >= 12 && respiratoryRate <= 20) return 'normal';
    if ((respiratoryRate > 20 && respiratoryRate <= 24) ||
        (respiratoryRate < 12 && respiratoryRate >= 10)) {
      return 'warning';
    }
    return 'emergency'; // >24 or <10
  }

  String get bloodPressureStatus {
    if (systolicBP < 120 && diastolicBP < 80) return 'normal';
    if ((systolicBP >= 120 && systolicBP < 130) && diastolicBP < 80) {
      return 'elevated';
    }

    if ((systolicBP >= 130 && systolicBP < 140) ||
        (diastolicBP >= 80 && diastolicBP < 90)) {
      return 'hypertension stage 1';
    }
    if (systolicBP >= 140 || diastolicBP >= 90) return 'hypertension stage 2';
    return 'emergency'; // Hypertensive crisis
  }

  String get overallStatus {
    final statuses = [
      heartRateStatus,
      spO2Status,
      bodyTempStatus,
      respiratoryRateStatus,
      bloodPressureStatus,
    ];

    if (statuses.contains('emergency')) return 'emergency';
    if (statuses.contains('warning')) return 'warning';
    return 'normal';
  }
}
