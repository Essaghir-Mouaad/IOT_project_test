import 'package:brew_crew/models/vital_data_model.dart';
import 'package:brew_crew/screens/home/components/latest_vitals_compo/analyse_vitals.dart';
import 'package:brew_crew/screens/home/components/latest_vitals_compo/latest_vitals.dart';
import 'package:brew_crew/services/database.dart';
import 'package:brew_crew/shared/loading.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DeviceDashboard extends StatefulWidget {
  final String deviceId;
  final DatabaseService db;
  final VoidCallback onDisconnect;
  final Future<void> Function() onLogout;

  const DeviceDashboard({
    super.key,
    required this.deviceId,
    required this.db,
    required this.onDisconnect,
    required this.onLogout,
  });

  @override
  State<DeviceDashboard> createState() => _DeviceDashboardState();
}

class _DeviceDashboardState extends State<DeviceDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("device-ID: ${widget.deviceId}"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),

        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Latest Vitals'),
            Tab(text: 'History'),
            Tab(text: 'Settings'),
          ],
        ),
        backgroundColor: Colors.blue[300],
        actions: [
          // ── Device status dot ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: StreamBuilder<DatabaseEvent>(
              stream: widget.db.deviceStatusStream(widget.deviceId),
              builder: (context, snap) {
                String label = 'checking...';
                Color color = Colors.grey;

                if (snap.hasData && snap.data!.snapshot.exists) {
                  label =
                      snap.data!.snapshot.value?.toString().toLowerCase() ??
                      'unknown';
                  color = label == 'online' ? Colors.green : Colors.red;
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 10, color: color),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Disconnect ────────────────────────────────
          IconButton(
            tooltip: 'Disconnect device',
            icon: const Icon(Icons.link_off, color: Colors.white),
            onPressed: widget.onDisconnect,
          ),

          // ── Logout ────────────────────────────────────
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_outlined, color: Colors.white),
            onPressed: () async => await widget.onLogout(),
          ),
        ],
      ),

      body: Container(
        color: Colors.white60,
        child: TabBarView(
          controller: _tabController,
          children: [
            KeepAliveWidget(
              child: StreamBuilder<DatabaseEvent>(
                stream: widget.db.latestVitalsStream(widget.deviceId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Loading());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
                    return const Center(
                      child: Text('No vitals data available yet.'),
                    );
                  }

                  final raw = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );
                  final vital = VitalDataModel.fromMap('latest', raw);

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LatestVitals(
                          heart: vital.heartRate,
                          temperature: vital.bodyTemp,
                          spo2: vital.spO2,
                          airQuality: vital.respiratoryRate,
                        ),
                        AnalyseVitals(
                          heartStatus: vital.heartRateStatus,
                          temperatureStatus: vital.bodyTempStatus,
                          spo2Status: vital.spO2Status,
                          airQualityStatus: vital.respiratoryRateStatus,
                          overallStatus: vital.overallStatus,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Center(child: Text('History coming soon')),

            const Center(child: Text('Settings coming soon')),
          ],
        ),
      ),
    );
  }
}

// this stat helps the app to keep in momory all the data of the device dashboard even when we switch between the tabs, so we don't have to reload the data every time we switch back to the latest vitals tab for example

class KeepAliveWidget extends StatefulWidget {
  final Widget child;
  const KeepAliveWidget({required this.child, super.key});

  @override
  State<KeepAliveWidget> createState() => _KeepAliveWidgetState();
}

class _KeepAliveWidgetState extends State<KeepAliveWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
