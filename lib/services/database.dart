import 'package:firebase_database/firebase_database.dart';



class DatabaseService {
  final String uid;
  DatabaseService({required this.uid});

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ─── Path helpers ────────────────────────────────────────────────
  DatabaseReference _userRef() => _db.ref('users/$uid');
  DatabaseReference _deviceRef(String id) => _db.ref('devices/$id');
  DatabaseReference _vitalsLatest(String id) => _db.ref('vitals/$id/latest');
  DatabaseReference _vitalsHistory(String id) => _db.ref('vitals/$id/history');
  DatabaseReference _envLatest(String id) => _db.ref('environment/$id/latest');
  DatabaseReference _envHistory(String id) =>
      _db.ref('environment/$id/history');
  DatabaseReference _locationCurrent(String id) =>
      _db.ref('location/$id/current');
  DatabaseReference _alerts(String id) => _db.ref('alerts/$id');



  // ════════════════════════════════════════════════════════════════
  // SEED  — call once from home.dart initState, then remove the call
  // ════════════════════════════════════════════════════════════════

  Future<void> seedFakeData() async {
    const String deviceId = 'esp32_001';

    final int now = DateTime.now().millisecondsSinceEpoch;

    // User profile
    await _userRef().set({
      'uid': uid,
      'name': 'Mouaad',
      'email': 'mouaad@email.com',
      'role': 'caregiver',
      'deviceId': deviceId,
    });

    // Device
    await _deviceRef(deviceId).set({
      'deviceId': deviceId,
      'name': 'ESP32 - Chambre',
      'status': 'online',
      'lastUpdate': now,
      'ownerId': uid,
    });

    // Latest vitals (ESP32 will overwrite this every few seconds)
    await _vitalsLatest(deviceId).set({
      'heartRate': 72.0,
      'spO2': 98.0,
      'bodyTemp': 36.8,
      'timestamp': now,
    });

    // Vitals history (push() creates a unique key automatically)
    final List<Map<String, dynamic>> vHistory = [
      {
        'heartRate': 68.0,
        'spO2': 97.0,
        'bodyTemp': 36.5,
        'timestamp': now - 600000,
      },
      {
        'heartRate': 70.0,
        'spO2': 97.5,
        'bodyTemp': 36.6,
        'timestamp': now - 480000,
      },
      {
        'heartRate': 73.0,
        'spO2': 98.0,
        'bodyTemp': 36.7,
        'timestamp': now - 360000,
      },
      {
        'heartRate': 75.0,
        'spO2': 98.5,
        'bodyTemp': 36.9,
        'timestamp': now - 240000,
      },
      {
        'heartRate': 71.0,
        'spO2': 99.0,
        'bodyTemp': 36.7,
        'timestamp': now - 120000,
      },
      {'heartRate': 72.0, 'spO2': 98.0, 'bodyTemp': 36.8, 'timestamp': now},
    ];
    
    for (final e in vHistory) {
      await _vitalsHistory(deviceId).push().set(e);
    }

    // Latest environment
    await _envLatest(
      deviceId,
    ).set({'temperature': 22.5, 'humidity': 55.0, 'timestamp': now});

    // Environment history
    final List<Map<String, dynamic>> eHistory = [
      {'temperature': 21.0, 'humidity': 52.0, 'timestamp': now - 360000},
      {'temperature': 22.0, 'humidity': 54.0, 'timestamp': now - 180000},
      {'temperature': 22.5, 'humidity': 55.0, 'timestamp': now},
    ];
    
    for (final e in eHistory) {
      await _envHistory(deviceId).push().set(e);
    }

    // GPS location
    await _locationCurrent(deviceId).set({
      'latitude': 31.6295,
      'longitude': -7.9811, // Marrakech
      'timestamp': now,
    });

    // Alerts
    final List<Map<String, dynamic>> alertList = [
      {
        'type': 'fall',
        'level': 'high',
        'message': 'Chute détectée ! Vérifiez immédiatement.',
        'status': 'unread',
        'timestamp': now - 600000,
      },
      {
        'type': 'no_motion',
        'level': 'medium',
        'message': 'Absence de mouvement depuis 30 minutes.',
        'status': 'unread',
        'timestamp': now - 1800000,
      },
      {
        'type': 'critical_vital',
        'level': 'high',
        'message': 'Fréquence cardiaque anormale : 110 BPM.',
        'status': 'read',
        'timestamp': now - 3600000,
      },
      {
        'type': 'unusual_location',
        'level': 'low',
        'message': 'Localisation inhabituelle détectée.',
        'status': 'read',
        'timestamp': now - 7200000,
      },
    ];
    
    for (final alert in alertList) {
      await _alerts(deviceId).push().set(alert);
    }

    print('Realtime DB seeded successfully — device: $deviceId');
  }



  // ════════════════════════════════════════════════════════════════
  // USER
  // ════════════════════════════════════════════════════════════════

  /// Read user profile once → gives you the deviceId to use everywhere else.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final snap = await _userRef().get();
    if (snap.exists) return Map<String, dynamic>.from(snap.value as Map);
    return null;
  }

  // ════════════════════════════════════════════════════════════════
  // VITALS
  // ════════════════════════════════════════════════════════════════

  /// Live stream of latest vitals — your home dashboard uses this.
  Stream<DatabaseEvent> latestVitalsStream(String deviceId) {
    return _vitalsLatest(deviceId).onValue;
  }

  /// One-time fetch of the last [limit] history entries (for charts).
  Future<List<Map<String, dynamic>>> getVitalsHistory(
    String deviceId, {
    int limit = 20,
  }) async {
    final snap = await _vitalsHistory(
      deviceId,
    ).orderByChild('timestamp').limitToLast(limit).get();
    if (!snap.exists) return [];
    final raw = Map<String, dynamic>.from(snap.value as Map);
    final list = raw.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    list.sort(
      (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
    );
    return list;
  }

  // ════════════════════════════════════════════════════════════════
  // ENVIRONMENT
  // ════════════════════════════════════════════════════════════════

  Stream<DatabaseEvent> latestEnvironmentStream(String deviceId) {
    return _envLatest(deviceId).onValue;
  }

  Future<List<Map<String, dynamic>>> getEnvironmentHistory(
    String deviceId, {
    int limit = 20,
  }) async {
    final snap = await _envHistory(
      deviceId,
    ).orderByChild('timestamp').limitToLast(limit).get();
    if (!snap.exists) return [];
    final raw = Map<String, dynamic>.from(snap.value as Map);
    final list = raw.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    list.sort(
      (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int),
    );
    return list;
  }

  // ════════════════════════════════════════════════════════════════
  // LOCATION
  // ════════════════════════════════════════════════════════════════

  Stream<DatabaseEvent> locationStream(String deviceId) {
    return _locationCurrent(deviceId).onValue;
  }

  // ════════════════════════════════════════════════════════════════
  // ALERTS
  // ════════════════════════════════════════════════════════════════

  /// Live stream of all alerts ordered by timestamp.
  Stream<DatabaseEvent> alertsStream(String deviceId) {
    return _alerts(deviceId).orderByChild('timestamp').onValue;
  }

  /// Mark a single alert as read using its push key.
  Future<void> markAlertAsRead(String deviceId, String alertKey) async {
    await _alerts(deviceId).child(alertKey).update({'status': 'read'});
  }

  // ════════════════════════════════════════════════════════════════
  // DEVICE STATUS
  // ════════════════════════════════════════════════════════════════

  Stream<DatabaseEvent> deviceStatusStream(String deviceId) {
    return _deviceRef(deviceId).child('status').onValue;
  }
}
