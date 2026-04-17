import 'package:brew_crew/screens/home/components/schedual/schedual.dart';
import 'package:brew_crew/screens/home/components/send_message/send_alert.dart';
import 'package:brew_crew/screens/home/device_dashboard.dart';
import 'package:brew_crew/screens/home/components/prediction_compo/predictions.dart';
import 'package:brew_crew/services/database.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class HomeWrapper extends StatefulWidget {
  final String deviceId;
  final DatabaseService db;
  final VoidCallback onDisconnect;
  final Future<void> Function() onLogout;

  const HomeWrapper({
    super.key,
    required this.deviceId,
    required this.db,
    required this.onDisconnect,
    required this.onLogout,
  });

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _currentPageIndex = 0; // Track current page (0=Dashboard, 1=Predictions)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  // ══════════════════
  // APP BAR
  // ══════════════════

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.deviceId),
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.blue[300],
      actions: [_buildDeviceStatus()],
    );
  }

  Widget _buildDeviceStatus() {
    return Padding(
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

          return Container(
            padding: const EdgeInsets.all(5),
            margin: const EdgeInsets.fromLTRB(0, 0, 4, 0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              border: Border.all(color: color, width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 15, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ══════════════════
  // DRAWER
  // ══════════════════

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.blue[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            _buildDrawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Device Dashboard',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentPageIndex = 0;
                });
              },
            ),
            _buildDrawerItem(
              icon: Icons.batch_prediction_outlined,
              title: 'Predictions',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentPageIndex = 1;
                });
              },
            ),
            _buildDrawerItem(
              icon: Icons.switch_access_shortcut_add_sharp,
              title: "Schedual",
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentPageIndex = 2;
                });
              },
            ),

            _buildDrawerItem(
              icon: Icons.emergency_share_outlined,
              title: "Send Alert",
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentPageIndex = 3;
                });
              },
            ),

            const Divider(),
            _buildDrawerItem(
              icon: Icons.link_off,
              title: 'Disconnect Device',
              onTap: () {
                Navigator.pop(context);
                widget.onDisconnect();
              },
            ),
            _buildDrawerItem(
              icon: Icons.logout_outlined,
              title: 'Logout',
              onTap: () async {
                Navigator.pop(context);
                await widget.onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.dashboard_outlined, size: 50),
            const SizedBox(width: 10),
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color.fromARGB(255, 140, 77, 151),
        size: 30,
      ),
      title: Text(title),
      onTap: onTap,
    );
  }

  // ════════════════════
  // BODY - Page Switcher
  // ════════════════════

  Widget _buildBody() {
    // Use _currentPageIndex to show the right page without TabBarView
    return _currentPageIndex == 0
        ? DeviceDashboard(deviceId: widget.deviceId, db: widget.db)
        : _currentPageIndex == 1
        ? const Predictions()
        : _currentPageIndex == 2
        ? const Schedual()
        : const SendAlert();
  }
}
