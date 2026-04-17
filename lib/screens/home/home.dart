import 'package:brew_crew/screens/home/components/link_device.dart';
import 'package:brew_crew/screens/home/home_wrapper.dart';
import 'package:brew_crew/services/auth.dart';
import 'package:brew_crew/services/database.dart';
import 'package:brew_crew/shared/loading.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  final String uid;
  const Home({super.key, required this.uid});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final DatabaseService _db;
  final AuthService _auth = AuthService();

  // null  → still seeding / loading
  // ''    → show device entry screen
  // 'ID'  → device connected, show dashboard
  String? _connectedDeviceId;
  bool _isSeeding = true;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService(uid: widget.uid);
    _initApp();
  }

  Future<void> _initApp() async {
    // Always start at the device entry screen on every login
    if (mounted) {
      setState(() {
        _isSeeding = false;
        _connectedDeviceId = ''; // empty string → show LinkDevice
      });
    }
  }

  void _onDeviceLinked(String deviceId) {
    setState(() => _connectedDeviceId = deviceId);
  }

  void _onDisconnect() {
    setState(() => _connectedDeviceId = '');
  }

  @override
  Widget build(BuildContext context) {
    // ── Loading / seeding splash ─────────────────────────────
    if (_isSeeding) {
      return const Scaffold(body: Center(child: Loading()));
    }

    // ── Device entry gate (always shown on login) ────────────
    if (_connectedDeviceId == null || _connectedDeviceId!.isEmpty) {
      return LinkDevice(
        onDeviceLinked: _onDeviceLinked,
        onLogout: () async => await _auth.signOut(),
        db: _db,
      );
    }

    // ── Device dashboard ─────────────────────────────────────
    return HomeWrapper(deviceId: _connectedDeviceId!, db: _db, onDisconnect: _onDisconnect, onLogout: () async => await _auth.signOut());
  }
}
