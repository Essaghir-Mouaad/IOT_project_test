import 'package:brew_crew/models/vital_data_model.dart';
import 'package:brew_crew/screens/home/components/sensors_history.dart';
import 'package:brew_crew/screens/home/components/latest_vitals_compo/latest_vitals_analysis.dart';
import 'package:brew_crew/services/database.dart';
import 'package:brew_crew/shared/loading.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DeviceDashboard extends StatefulWidget {
  final String deviceId;
  final DatabaseService db;

  const DeviceDashboard({super.key, required this.deviceId, required this.db});

  @override
  State<DeviceDashboard> createState() => _DeviceDashboardState();
}

class _DeviceDashboardState extends State<DeviceDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VitalDataModel? vitalsData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: TabBar(
          indicatorColor: Colors.redAccent,
          labelColor: Colors.pinkAccent,
          controller: _tabController,
          tabs: const [
            Tab(
              child: Text(
                "Latest Vit",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Tab(
              child: Text(
                "History",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),

              // icon: Icon(Icons.history_outlined, size: 25, color: Colors.green),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Container(
      color: Colors.white60,
      child: TabBarView(
        controller: _tabController,
        children: [_buildLatestVitalsTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildLatestVitalsTab() {
    return KeepAliveWidget(
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
            return const Center(child: Text('No vitals data available yet.'));
          }

          final raw = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );
          final vital = VitalDataModel.fromMap('latest', raw);
          vitalsData = vital;

          return LatestVitalsAnalysis(vital: vital);
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    return KeepAliveWidget(
      child: SensorsHistory(deviceId: widget.deviceId, db: widget.db),
    );
  }
}

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
