import 'package:brew_crew/models/vital_data_model.dart';
import 'package:brew_crew/services/database.dart';
import 'package:brew_crew/shared/loading.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  final String uid;

  const Home({super.key, required this.uid});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final DatabaseService _db;

  String _status = 'Loading user profile...';
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService(uid: widget.uid);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Loading();
      setState(() => _status = 'Reading profile...');
      final profile = await _db.getUserProfile();

      if (profile == null) {
        setState(() {
          _status =
              'No user profile found under users/${widget.uid}.\n'
              'Create it first with a deviceId field (for example: esp32_001).';
        });
        return;
      }

      final deviceId = (profile['deviceId'] ?? '').toString().trim();
      if (deviceId.isEmpty) {
        setState(() {
          _status =
              'Profile found, but deviceId is missing.\n'
              'Add deviceId in users/${widget.uid}/deviceId.';
        });
        return;
      }

      setState(() {
        _deviceId = deviceId;
        _status =
            'Connected to realtime stream.\n\n'
            'Name     : ${profile['name']}\n'
            'Role     : ${profile['role']}\n'
            'DeviceId : $deviceId';
      });
    } catch (e) {
      setState(() => _status = 'Error while loading profile:\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deviceId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_status, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: _db.latestVitalsStream(_deviceId!),
      builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Home')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Home')),
            body: const Center(child: Text('No realtime vitals available yet')),
          );
        }

        final raw = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );

        final vital = VitalDataModel.fromMap("latest", raw);
        return Scaffold(
          appBar: AppBar(title: const Text('Home')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text('Latest Vitals:'),
                Text('Heart Rate: ${vital.heartRate} bpm'),
                Text('SpO2: ${vital.spO2}%'),
                Text('Temperature: ${vital.bodyTemp} °C'),
              ],
            ),
          ),
        );
      },
    );
  }
}
