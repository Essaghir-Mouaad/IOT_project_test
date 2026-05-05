// ════════════════════════════════════════════════════════════════════════════
// SENSOR DATA SYSTEM - USAGE GUIDE
// ════════════════════════════════════════════════════════════════════════════
//
// Each device now has 6 individual sensors with real-time + historical data
// Database structure:
// sensors/
//   ├── {deviceId}/
//   │   ├── sensor_1/
//   │   │   ├── latest    (real-time data)
//   │   │   └── history   (all readings)
//   │   ├── sensor_2/...
//   │   └── sensor_6/...
//
// ════════════════════════════════════════════════════════════════════════════

import 'package:brew_crew/services/database.dart';

class SensorUsageExamples {
  final String userId = 'user123';
  final String deviceId = 'device456';

  late final DatabaseService _db = DatabaseService(uid: userId);
  // ─────────────────────────────────────────────────────────────────────────
  // 1. LISTEN TO REAL-TIME SENSOR LATEST (FLAT STRUCTURE)
  // ─────────────────────────────────────────────────────────────────────────
  void listenToSensorsRealTime() {
    final stream = _db.latestSensorsStream(deviceId);

    stream.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        // `data` contains flat sensor fields (accelerometerX, batteryLevel, ...)
        print('Sensors latest (flat): $data');
        // Update UI here using `data` or map into your models
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. GET LATEST FLAT READING FOR A DEVICE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> getLatestSensorsReading() async {
    final data = await _db.getSensorLatestFlat(deviceId);
    if (data != null) {
      print('Latest flat sensors: $data');
      // Convert to your UI model if needed
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. GET HISTORICAL FLAT SENSOR DATA FOR CHARTS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> getHistoricalFlatDataForChart() async {
    final history = await _db.getSensorHistoryFlat(deviceId, limit: 100);

    if (history.isNotEmpty) {
      // `history` is a List<Map<String, dynamic>> of previous flat snapshots
      print('Got ${history.length} historical flat readings');
      // Example: extract a time series for `batteryLevel`
      final batterySeries = history
          .map((m) => (m['batteryLevel'] as num).toDouble())
          .toList();
      print('Battery series length: ${batterySeries.length}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. ADD A NEW SENSOR READING (archives previous latest -> history)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> recordNewSensorReading() async {
    final sensorData = {
      'batteryLevel': 98,
      'isCharging': false,
      'motionDetected': false,
    };

    await _db.addSensorReading(deviceId, sensorData);
    print('Saved flat sensor reading');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. INITIALIZE SENSORS FOR A NEW DEVICE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> setupNewDevice() async {
    await _db.initializeDeviceSensors(deviceId);
    print('Initialized sensors (flat) for device');
  }
}

// ════════════════════════════════════════════════════════════════════════════
// INTEGRATION WITH CHART LIBRARY (fl_chart example)
// ════════════════════════════════════════════════════════════════════════════
/*
Future<void> buildSensorChart() async {
  final history = await _db.getSensorHistory(deviceId, 1, limit: 50);
  
  if (history.isEmpty) return;
  
  final chartData = history
      .asMap()
      .entries
      .map((e) => FlSpot(
        e.key.toDouble(),
        (e.value['value'] as num).toDouble(),
      ))
      .toList();
  
  // Use chartData with LineChart, BarChart, etc.
}
*/

// ════════════════════════════════════════════════════════════════════════════
// DATABASE STRUCTURE REFERENCE
// ════════════════════════════════════════════════════════════════════════════
/*
Firebase Realtime DB:
{
  "sensors": {
    "device456": {
      "sensor_1": {
        "latest": {
          "value": 23.5,
          "unit": "°C",
          "status": "online",
          "label": "Temperature",
          "timestamp": 1650000000000
        },
        "history": {
          "hist_key_1": { "value": 23.0, "unit": "°C", "timestamp": 1649999999000 },
          "hist_key_2": { "value": 23.5, "unit": "°C", "timestamp": 1650000000000 }
        }
      },
      "sensor_2": { ... },
      "sensor_3": { ... },
      "sensor_4": { ... },
      "sensor_5": { ... },
      "sensor_6": { ... }
    }
  }
}
*/
