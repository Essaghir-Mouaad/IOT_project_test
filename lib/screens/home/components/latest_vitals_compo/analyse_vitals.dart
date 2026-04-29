import 'package:brew_crew/shared/status_items.dart';
import 'package:flutter/material.dart';

class AnalyseVitals extends StatelessWidget {
  final String overallStatus;
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
        return const Color(0xFF3DBF7A);
      case 'warning':
        return const Color(0xFFF5963D);
      case 'emergency':
        return const Color(0xFFE05252);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'normal':
        return Icons.check_circle_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'emergency':
        return Icons.error_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overallColor = _getStatusColor(overallStatus);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: overallColor.withValues(alpha: .2),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: overallColor.withValues(alpha: .07),
              border: Border(
                bottom: BorderSide(
                  color: overallColor.withValues(alpha: .2),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: overallColor.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getStatusIcon(overallStatus),
                    color: overallColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Health Status',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .9),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      overallStatus[0].toUpperCase() +
                          overallStatus.substring(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: overallColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Status Items ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                StatusItem(
                  title: 'Heart Rate',
                  status: heartStatus,
                  icon: Icons.favorite_rounded,
                  statusColor: _getStatusColor(heartStatus),
                ),
                const SizedBox(height: 10),
                StatusItem(
                  title: 'Temperature',
                  status: temperatureStatus,
                  icon: Icons.thermostat_rounded,
                  statusColor: _getStatusColor(temperatureStatus),
                ),
                const SizedBox(height: 10),
                StatusItem(
                  title: 'SpO2 Level',
                  status: spo2Status,
                  icon: Icons.water_drop_rounded,
                  statusColor: _getStatusColor(spo2Status),
                ),
                const SizedBox(height: 10),
                StatusItem(
                  title: 'Respiratory Rate',
                  status: airQualityStatus,
                  icon: Icons.air_rounded,
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
