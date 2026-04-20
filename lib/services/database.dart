import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ─────────────────────────────────────────────
  // PATHS
  // ─────────────────────────────────────────────

  DatabaseReference _userRef() => _db.ref('users/$uid');
  DatabaseReference _deviceRef(String id) => _db.ref('devices/$id');

  DatabaseReference _vitalsLatest(String id) => _db.ref('vitals/$id/latest');
  DatabaseReference _vitalsHistory(String id) => _db.ref('vitals/$id/history');

  DatabaseReference _envLatest(String id) => _db.ref('environment/$id/latest');
  DatabaseReference _envHistory(String id) =>
      _db.ref('environment/$id/history');

  DatabaseReference _locationCurrent(String id) =>
      _db.ref('location/$id/current');
  DatabaseReference _locationHistory(String id) =>
      _db.ref('location/$id/history');

  DatabaseReference _alerts(String id) => _db.ref('alerts/$id');

  // Individual sensor paths (6 sensors per device)
  DatabaseReference _sensorLatest(String deviceId, int sensorNum) =>
      _db.ref('sensors/$deviceId/sensor_$sensorNum/latest');
  DatabaseReference _sensorHistory(String deviceId, int sensorNum) =>
      _db.ref('sensors/$deviceId/sensor_$sensorNum/history');

  // Legacy paths (kept for compatibility)
  DatabaseReference _sensorsLatest(String id) => _db.ref('sensors/$id/latest');
  DatabaseReference _sensorsHistory(String id) =>
      _db.ref('sensors/$id/history');

  // ═════════════════════════════════════════════
  // USER
  // ═════════════════════════════════════════════

  /// Create user WITHOUT devices
  Future<void> createUser({
    required String name,
    required String email,
    String role = 'caregiver',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _userRef().set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'linkedDeviceIds': [], // 🔥 now a list
      'createdAt': now,
    });
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final snap = await _userRef().get();
    if (!snap.exists) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  /// Get all device IDs linked to this user
  Future<List<String>> getLinkedDeviceIds() async {
    final profile = await getUserProfile();
    if (profile == null) return [];
    final raw = profile['linkedDeviceIds'];
    if (raw == null) return [];
    if (raw is List) return raw.cast<String>();
    // Handle Firebase storing list as map {0: 'id', 1: 'id'}
    if (raw is Map) return raw.values.cast<String>().toList();
    return [];
  }

  /// Link a device to this user (supports multiple devices)
  Future<String> linkDevice(String deviceId) async {
    final deviceSnap = await _deviceRef(deviceId).get();

    if (!deviceSnap.exists) return "Device not found";

    final deviceData = Map<String, dynamic>.from(deviceSnap.value as Map);

    // Get existing linked users
    final linkedTo = deviceData['linkedTo'] is Map
        ? Map<String, dynamic>.from(deviceData['linkedTo'] as Map)
        : <String, dynamic>{};

    // ── Check if already linked ───────────────────────
    if (linkedTo.containsKey(uid)) {
      return "Device already linked to your account";
    }

    // ── Check if device is at max capacity (2 users) ──
    if (linkedTo.length >= 2) {
      return "Device can only be linked to 2 users maximum";
    }

    // ── Link this user ────────────────────────────────
    final updatedLinkedTo = {...linkedTo, uid: true};
    final currentIds = await getLinkedDeviceIds();
    final updatedIds = [...currentIds, deviceId];

    await _userRef().update({'linkedDeviceIds': updatedIds});
    await _deviceRef(deviceId).update({'linkedTo': updatedLinkedTo});

    return "success";
  }

  /// Unlink a device from this user
  Future<void> unlinkDevice(String deviceId) async {
    final currentIds = await getLinkedDeviceIds();
    final updatedIds = currentIds.where((id) => id != deviceId).toList();

    await _userRef().update({'linkedDeviceIds': updatedIds});

    // Remove this user from device's linkedTo
    final deviceSnap = await _deviceRef(deviceId).get();
    if (deviceSnap.exists) {
      final deviceData = Map<String, dynamic>.from(deviceSnap.value as Map);
      final linkedTo = deviceData['linkedTo'] is Map
          ? Map<String, dynamic>.from(deviceData['linkedTo'] as Map)
          : <String, dynamic>{};

      linkedTo.remove(uid);

      if (linkedTo.isEmpty) {
        await _deviceRef(deviceId).update({'linkedTo': null});
      } else {
        await _deviceRef(deviceId).update({'linkedTo': linkedTo});
      }
    }
  }

  // ═════════════════════════════════════════════
  // DEVICE STATUS
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> deviceStatusStream(String deviceId) {
    return _deviceRef(deviceId).child('status').onValue.asBroadcastStream();
  }

  Future<Map<String, dynamic>?> getDeviceInfo(String deviceId) async {
    final snap = await _deviceRef(deviceId).get();
    if (!snap.exists) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  // ═════════════════════════════════════════════
  // VITALS
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> latestVitalsStream(String deviceId) {
    return _vitalsLatest(deviceId).onValue.asBroadcastStream();
  }

  Future<List<Map<String, dynamic>>> getVitalsHistory(
    String deviceId, {
    int limit = 20,
  }) async {
    final snap = await _vitalsHistory(deviceId).get();

    if (!snap.exists) return [];

    final raw = Map<String, dynamic>.from(snap.value as Map);
    final list = raw.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    list.sort(
      (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
    );
    if (list.length <= limit) return list;
    return list.sublist(list.length - limit);
  }

  // ═════════════════════════════════════════════
  // ENVIRONMENT
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> latestEnvironmentStream(String deviceId) {
    return _envLatest(deviceId).onValue.asBroadcastStream();
  }

  Future<List<Map<String, dynamic>>> getEnvironmentHistory(
    String deviceId, {
    int limit = 20,
  }) async {
    final snap = await _envHistory(deviceId).get();

    if (!snap.exists) return [];

    final raw = Map<String, dynamic>.from(snap.value as Map);
    final list = raw.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    list.sort(
      (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
    );
    if (list.length <= limit) return list;
    return list.sublist(list.length - limit);
  }

  // ═════════════════════════════════════════════
  // SENSORS (Individual Sensors - 6 per Device)
  // ═════════════════════════════════════════════

  /// Check if device sensors have been initialized with data
  Future<bool> hasDeviceSensorData(String deviceId) async {
    try {
      // Check if at least one sensor has history data
      for (int i = 1; i <= 6; i++) {
        final snap = await _sensorHistory(deviceId, i).limitToFirst(1).get();
        if (snap.exists) return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  Stream<DatabaseEvent> sensorStream(String deviceId, int sensorNum) {
    if (sensorNum < 1 || sensorNum > 6) {
      throw Exception('Sensor number must be between 1 and 6');
    }
    return _sensorLatest(deviceId, sensorNum)
        .onValue
        .asBroadcastStream();
  }

  /// Get latest reading for a specific sensor
  Future<Map<String, dynamic>?> getSensorLatest(
    String deviceId,
    int sensorNum,
  ) async {
    if (sensorNum < 1 || sensorNum > 6) {
      throw Exception('Sensor number must be between 1 and 6');
    }
    final snap = await _sensorLatest(deviceId, sensorNum).get();
    if (!snap.exists) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  /// Get historical data for a specific sensor
  Future<List<Map<String, dynamic>>> getSensorHistory(
    String deviceId,
    int sensorNum, {
    int limit = 100,
  }) async {
    if (sensorNum < 1 || sensorNum > 6) {
      throw Exception('Sensor number must be between 1 and 6');
    }
    final snap = await _sensorHistory(deviceId, sensorNum).get();

    if (!snap.exists) return [];

    final raw = Map<String, dynamic>.from(snap.value as Map);
    final list = raw.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    list.sort(
      (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
    );
    if (list.length <= limit) return list;
    return list.sublist(list.length - limit);
  }

  /// Add a new sensor reading to history
  Future<void> addSensorReading(
    String deviceId,
    int sensorNum,
    Map<String, dynamic> data,
  ) async {
    if (sensorNum < 1 || sensorNum > 6) {
      throw Exception('Sensor number must be between 1 and 6');
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final dataWithTimestamp = {...data, 'timestamp': timestamp};

    // Update latest reading
    await _sensorLatest(deviceId, sensorNum).set(dataWithTimestamp);

    // Add to history
    await _sensorHistory(deviceId, sensorNum)
        .push()
        .set(dataWithTimestamp);
  }

  /// Initialize 6 sensors for a new device
  Future<void> initializeDeviceSensors(String deviceId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final initData = {
      'value': 0,
      'unit': 'unknown',
      'status': 'offline',
      'timestamp': timestamp,
    };

    for (int i = 1; i <= 6; i++) {
      await _sensorLatest(deviceId, i).set(initData);
    }
  }

  /// Get all 6 sensors latest data as a map
  Future<Map<int, Map<String, dynamic>>> getAllSensorsLatest(
      String deviceId) async {
    final result = <int, Map<String, dynamic>>{};
    for (int i = 1; i <= 6; i++) {
      final snap = await _sensorLatest(deviceId, i).get();
      if (snap.exists) {
        result[i] = Map<String, dynamic>.from(snap.value as Map);
      }
    }
    return result;
  }

  // Legacy methods (for compatibility)
  Stream<DatabaseEvent> latestSensorsStream(String deviceId) {
    return _sensorsLatest(deviceId).onValue.asBroadcastStream();
  }

  /// Get historical data for all sensors combined (legacy)
  /// Use getSensorHistory() for individual sensor history
  @Deprecated(
      'Use getSensorHistory(deviceId, sensorNum) for individual sensors')
  Future<List<Map<String, dynamic>>> getSensorsHistory(
    String deviceId, {
    int limit = 20,
  }) async {
    final snap = await _sensorsHistory(deviceId).get();

    if (!snap.exists) return [];

    final raw = Map<String, dynamic>.from(snap.value as Map);
    final list = raw.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    list.sort(
      (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
    );
    if (list.length <= limit) return list;
    return list.sublist(list.length - limit);
  }

  // ═════════════════════════════════════════════
  // LOCATION
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> locationStream(String deviceId) {
    return _locationCurrent(deviceId).onValue.asBroadcastStream();
  }

  Future<List<Map<String, dynamic>>> getLocationHistory(
    String deviceId, {
    int limit = 20,
  }) async {
    final snap = await _locationHistory(deviceId).get();

    if (!snap.exists) return [];

    final raw = Map<String, dynamic>.from(snap.value as Map);
    final list = raw.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    list.sort(
      (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
    );
    if (list.length <= limit) return list;
    return list.sublist(list.length - limit);
  }

  // ═════════════════════════════════════════════
  // ALERTS
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> alertsStream(String deviceId) {
    return _alerts(
      deviceId,
    ).orderByChild('timestamp').onValue.asBroadcastStream();
  }

  Future<void> markAlertAsRead(String deviceId, String alertKey) async {
    await _alerts(deviceId).child(alertKey).update({'status': 'read'});
  }
}
