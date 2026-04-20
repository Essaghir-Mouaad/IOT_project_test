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
import 'package:brew_crew/models/sensor_model.dart';

class SensorUsageExamples {
  final String userId = 'user123';
  final String deviceId = 'device456';

  late final DatabaseService _db = DatabaseService(uid: userId);

  // ─────────────────────────────────────────────────────────────────────────
  // 1. LISTEN TO REAL-TIME DATA FOR A SPECIFIC SENSOR
  // ─────────────────────────────────────────────────────────────────────────
  void listenToSensorRealTime() {
    // Listen to sensor 1 real-time updates
    final stream = _db.sensorStream(deviceId, 1);
    
    stream.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(
            event.snapshot.value as Map);
        final sensor = SensorModel.fromMap(1, data);
        print('Sensor 1 latest: $sensor');
        // Update UI here
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. GET LATEST READING FOR A SENSOR
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> getLatestSensorReading() async {
    final data = await _db.getSensorLatest(deviceId, 1);
    if (data != null) {
      final sensor = SensorModel.fromMap(1, data);
      print('Sensor 1: $sensor');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. GET HISTORICAL DATA FOR CHARTS (Most Important!)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> getHistoricalDataForChart() async {
    // Get last 100 readings for sensor 1
    final history = await _db.getSensorHistory(deviceId, 1, limit: 100);
    
    if (history.isNotEmpty) {
      // Convert to SensorModel list for easier use
      final sensors = history
          .map((data) => SensorModel.fromMap(1, data))
          .toList();
      
      // Now you can use this for charting:
      // - Extract values: sensors.map((s) => s.value).toList()
      // - Extract timestamps: sensors.map((s) => s.timestamp).toList()
      // - Pass to your chart library (fl_chart, syncfusion, etc.)
      
      print('Got ${sensors.length} historical readings');
      sensors.forEach((s) => print('  ${s.timestamp}: ${s.value} ${s.unit}'));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. ADD A NEW SENSOR READING (called by IoT device/backend)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> recordNewSensorReading() async {
    final sensorData = {
      'value': 23.5,
      'unit': '°C',
      'status': 'online',
      'label': 'Temperature Sensor',
    };
    
    await _db.addSensorReading(deviceId, 1, sensorData);
    print('Saved reading for sensor 1');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. INITIALIZE ALL 6 SENSORS FOR A NEW DEVICE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> setupNewDevice() async {
    await _db.initializeDeviceSensors(deviceId);
    print('Initialized 6 sensors for device');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. GET ALL 6 SENSORS' LATEST DATA AT ONCE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> getAllSensorsLatestData() async {
    final allSensors = await _db.getAllSensorsLatest(deviceId);
    
    allSensors.forEach((sensorNum, data) {
      final sensor = SensorModel.fromMap(sensorNum, data);
      print('Sensor $sensorNum: ${sensor.value} ${sensor.unit}');
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. EXAMPLE: MULTI-SENSOR CHART IN HISTORY TAB
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<int, List<SensorModel>>> getHistoryForAllSensors() async {
    final result = <int, List<SensorModel>>{};
    
    // Get history for all 6 sensors
    for (int i = 1; i <= 6; i++) {
      final history = await _db.getSensorHistory(deviceId, i, limit: 100);
      result[i] = history
          .map((data) => SensorModel.fromMap(i, data))
          .toList();
    }
    
    return result;
    // Usage: Display tabs/cards with charts for each sensor
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
