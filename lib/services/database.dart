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

  // ═════════════════════════════════════════════
  // SENSORS
  // ═════════════════════════════════════════════

  Stream<DatabaseEvent> latestSensorsStream(String deviceId) {
    return _sensorsLatest(deviceId).onValue.asBroadcastStream();
  }

  Future<List<Map<String, dynamic>>> getSensorsHistory(
    String deviceId, {
    int limit = 20,
  }) async {
    final snap = await _sensorsHistory(
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
    final snap = await _locationHistory(
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
