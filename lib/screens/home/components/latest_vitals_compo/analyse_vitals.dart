import 'package:brew_crew/shared/status_items.dart';
import 'package:flutter/material.dart';

class AnalyseVitals extends StatelessWidget {
  final String overallStatus; // 'normal', 'warning', 'emergency'
  final String heartStatus;
  final String temperatureStatus;
  final String spo2Status;
  final String airQualityStatus;

  const AnalyseVitals({
    super.key,
    required this.overallStatus,
    required this.heartStatus,
    required this.temperatureStatus,
    required this.spo2Status,
    required this.airQualityStatus,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'normal':
        return Colors.green;
      case 'warning':
        return Colors.amber;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'normal':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning_amber;
      case 'emergency':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overallColor = _getStatusColor(overallStatus);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header with Overall Status ──────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: overallColor.withValues(alpha: 0.09),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              border: Border(
                bottom: BorderSide(
                  color: overallColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(overallStatus),
                  color: overallColor,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Health Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      overallStatus.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: overallColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Status Items ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                StatusItem(
                  title: 'Heart Rate',
                  status: heartStatus,
                  icon: Icons.favorite,
                  statusColor: _getStatusColor(heartStatus),
                ),
                const SizedBox(height: 8),
                StatusItem(
                  title: 'Temperature',
                  status: temperatureStatus,
                  icon: Icons.thermostat,
                  statusColor: _getStatusColor(temperatureStatus),
                ),
                const SizedBox(height: 8),
                StatusItem(
                  title: 'SpO2 Level',
                  status: spo2Status,
                  icon: Icons.brightness_5,
                  statusColor: _getStatusColor(spo2Status),
                ),
                const SizedBox(height: 8),
                StatusItem(
                  title: 'Respiratory Rate',
                  status: airQualityStatus,
                  icon: Icons.air,
                  statusColor: _getStatusColor(airQualityStatus),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
