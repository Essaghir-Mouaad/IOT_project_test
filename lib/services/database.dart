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

  DatabaseReference _sensorsLatest(String id) => _db.ref('sensors/$id/latest');
  DatabaseReference _sensorsHistory(String id) =>
      _db.ref('sensors/$id/history');

  // ═════════════════════════════════════════════
  // USER
  // ═════════════════════════════════════════════

  Future<void> createUser({
    required String name,
    required String email,
    required int age,
    String role = 'caregiver',
  }) async {
    await _userRef().set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'age': age,
      'linkedDeviceIds': [],
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final snap = await _userRef().get();
    if (!snap.exists) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  Future<void> updateUserProfile({
    required String name,
    required String email,
    required String role,
    required int age,
  }) async {
    await _userRef().update({
      'name': name,
      'email': email,
      'role': role,
      'age': age,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<String>> getLinkedDeviceIds() async {
    final profile = await getUserProfile();
    if (profile == null) return [];
    final raw = profile['linkedDeviceIds'];
    if (raw == null) return [];
    if (raw is List) return raw.cast<String>();
    if (raw is Map) return raw.values.cast<String>().toList();
    return [];
  }

  /// Returns "success" or an error message.
  Future<String> linkDevice(String deviceId) async {
    final deviceSnap = await _deviceRef(deviceId).get();
    if (!deviceSnap.exists) return 'Device not found';

    final deviceData = Map<String, dynamic>.from(deviceSnap.value as Map);
    final linkedTo = deviceData['linkedTo'] is Map
        ? Map<String, dynamic>.from(deviceData['linkedTo'] as Map)
        : <String, dynamic>{};

    if (linkedTo.containsKey(uid))
      return 'Device already linked to your account';
    if (linkedTo.length >= 2)
      return 'Device can only be linked to 2 users maximum';

    final updatedIds = [...await getLinkedDeviceIds(), deviceId];

    await Future.wait([
      _userRef().update({'linkedDeviceIds': updatedIds}),
      _deviceRef(deviceId).update({
        'linkedTo': {...linkedTo, uid: true},
      }),
    ]);

    return 'success';
  }

  Future<void> unlinkDevice(String deviceId) async {
    final updatedIds = (await getLinkedDeviceIds())
        .where((id) => id != deviceId)
        .toList();

    final deviceSnap = await _deviceRef(deviceId).get();

    if (deviceSnap.exists) {
      final deviceData = Map<String, dynamic>.from(deviceSnap.value as Map);
      final linkedTo = deviceData['linkedTo'] is Map
          ? Map<String, dynamic>.from(deviceData['linkedTo'] as Map)
          : <String, dynamic>{};

      linkedTo.remove(uid);

      await Future.wait([
        _userRef().update({'linkedDeviceIds': updatedIds}),
        _deviceRef(
          deviceId,
        ).update({'linkedTo': linkedTo.isEmpty ? null : linkedTo}),
      ]);
    } else {
      await _userRef().update({'linkedDeviceIds': updatedIds});
    }
  }

  // ═════════════════════════════════════════════
  // DEVICE
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> deviceStatusStream(String deviceId) =>
      _deviceRef(deviceId).child('status').onValue.asBroadcastStream();

  Future<Map<String, dynamic>?> getDeviceInfo(String deviceId) async {
    final snap = await _deviceRef(deviceId).get();
    if (!snap.exists) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  // ═════════════════════════════════════════════
  // VITALS
  // Fields: heartRate, spo2, bodyTemp, activity,
  //         diastolicBP, systolicBP, respiratoryRate, timestamp
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> latestVitalsStream(String deviceId) =>
      _vitalsLatest(deviceId).onValue.asBroadcastStream();

  Future<List<Map<String, dynamic>>> getVitalsHistory(
    String deviceId, {
    int limit = 20,
  }) async {
    return _getHistoryList(_vitalsHistory(deviceId), limit: limit);
  }

  // ═════════════════════════════════════════════
  // ENVIRONMENT
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> latestEnvironmentStream(String deviceId) =>
      _envLatest(deviceId).onValue.asBroadcastStream();

  Future<List<Map<String, dynamic>>> getEnvironmentHistory(
    String deviceId, {
    int limit = 20,
  }) async {
    return _getHistoryList(_envHistory(deviceId), limit: limit);
  }

  // ═════════════════════════════════════════════
  // SENSORS (flat structure)
  // Fields: accelerometerX/Y/Z, gyroscopeX/Y/Z,
  //         batteryLevel, isCharging, motionDetected,
  //         signalStrength, timestamp
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> latestSensorsStream(String deviceId) =>
      _sensorsLatest(deviceId).onValue.asBroadcastStream();

  Future<Map<String, dynamic>?> getSensorLatestFlat(String deviceId) async {
    final snap = await _sensorsLatest(deviceId).get();
    if (!snap.exists) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  Future<List<Map<String, dynamic>>> getSensorHistoryFlat(
    String deviceId, {
    int limit = 100,
  }) async {
    return _getHistoryList(_sensorsHistory(deviceId), limit: limit);
  }

  /// Archives current latest to history, then writes [sensorData] as new latest.
  Future<void> addSensorReading(
    String deviceId,
    Map<String, dynamic> sensorData,
  ) async {
    final dataWithTs = {
      ...sensorData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final currentLatest = await _sensorsLatest(deviceId).get();
    if (currentLatest.exists) {
      await _sensorsHistory(
        deviceId,
      ).push().set(Map<String, dynamic>.from(currentLatest.value as Map));
    }

    await _sensorsLatest(deviceId).set(dataWithTs);
  }

  Future<void> initializeDeviceSensors(String deviceId) async {
    await _sensorsLatest(deviceId).set({
      'accelerometerX': 0.0,
      'accelerometerY': 0.0,
      'accelerometerZ': 9.81,
      'batteryLevel': 100,
      'gyroscopeX': 0.0,
      'gyroscopeY': 0.0,
      'gyroscopeZ': 0.0,
      'isCharging': false,
      'motionDetected': false,
      'signalStrength': -50,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ═════════════════════════════════════════════
  // LOCATION
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> locationStream(String deviceId) =>
      _locationCurrent(deviceId).onValue.asBroadcastStream();

  Future<List<Map<String, dynamic>>> getLocationHistory(
    String deviceId, {
    int limit = 20,
  }) async {
    return _getHistoryList(_locationHistory(deviceId), limit: limit);
  }

  // ═════════════════════════════════════════════
  // ALERTS
  // Fields: deviceId, message, severity, status, timestamp, type
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> alertsStream(String deviceId) =>
      _alerts(deviceId).orderByChild('timestamp').onValue.asBroadcastStream();

  Future<void> markAlertAsRead(String deviceId, String alertKey) async {
    await _alerts(deviceId).child(alertKey).update({'status': 'read'});
  }

  // ═════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════

  /// Generic sorted+limited history fetch for any history ref.
  Future<List<Map<String, dynamic>>> _getHistoryList(
    DatabaseReference ref, {
    required int limit,
  }) async {
    final snap = await ref.get();
    if (!snap.exists) return [];

    final list =
        (snap.value as Map).values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
          ..sort(
            (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
          );

    return list.length <= limit ? list : list.sublist(list.length - limit);
  }
}
