import 'package:brew_crew/models/vital_data_model.dart';
import 'package:brew_crew/services/database.dart';
import 'package:brew_crew/shared/loading.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:flutter/material.dart';

class SensorsHistory extends StatefulWidget {
  final String deviceId;
  final DatabaseService db;

  const SensorsHistory({super.key, required this.deviceId, required this.db});

  @override
  State<SensorsHistory> createState() => _SensorsHistoryState();
}

class _SensorsHistoryState extends State<SensorsHistory>
    with SingleTickerProviderStateMixin {
  late Future<_HistoryData> _historyFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_HistoryData> _loadHistory() async {
    final vitals = await _fetchVitalsHistory();
    return _HistoryData(vitals: vitals);
  }

  Future<List<VitalDataModel>> _fetchVitalsHistory() async {
    final raw = await widget.db.getVitalsHistory(widget.deviceId, limit: 120);
    return raw
        .asMap()
        .entries
        .map(
          (entry) => VitalDataModel.fromMap('hist_${entry.key}', entry.value),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HistoryData>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Loading());
        }

        if (snapshot.hasError) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Failed To Load History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _historyFuture = _loadHistory();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final historyData = snapshot.data ?? const _HistoryData.empty();
        final vitalsData = historyData.vitals;

        if (vitalsData.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'No vitals history available',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pull down to refresh or wait a moment...',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _historyFuture = _loadHistory();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _historyFuture = _loadHistory();
            });
          },
          child: Column(
            children: [
              // Tab selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(12),
                child: TabBar(
                  controller: _tabController,
                  // Use a BoxDecoration for the colored indicator but control
                  // its visible width with `indicatorPadding` so it occupies
                  // approximately half of each tab's width.
                  indicator: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  // For N tabs the horizontal padding per side to make the
                  // indicator half the tab width is: totalWidth * (1 / (4*N)).
                  indicatorPadding: EdgeInsets.symmetric(
                    horizontal:
                        MediaQuery.of(context).size.width *
                        (1 / (100 * _tabController.length)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[700],
                  tabs: const [
                    Tab(text: 'Per-Entry View'),
                    Tab(text: 'Summary'),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Per-entry view
                    _PerEntryView(vitals: vitalsData),
                    // Summary view
                    _SummaryView(vitals: vitalsData),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// VIEW 1: Per-entry charts showing each reading individually
class _PerEntryView extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _PerEntryView({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Per-Entry Vitals'),
          const SizedBox(height: 16),
          _HeartRateChart(vitals: vitals),
          const SizedBox(height: 16),
          _SpO2Chart(vitals: vitals),
          const SizedBox(height: 16),
          _BodyTemperatureChart(vitals: vitals),
          const SizedBox(height: 16),
          _RespiratoryRateChart(vitals: vitals),
          const SizedBox(height: 16),
          _BloodPressureChart(vitals: vitals),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// VIEW 2: Summary charts with aggregated statistics
class _SummaryView extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _SummaryView({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Summary Statistics'),
          const SizedBox(height: 16),
          _NormalizedMetricsChart(vitals: vitals),
          const SizedBox(height: 16),
          _SpO2GaugeChart(vitals: vitals),
          const SizedBox(height: 16),
          _HeartRateHistogram(vitals: vitals),
          const SizedBox(height: 16),
          _BloodPressureGroupedChart(vitals: vitals),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PER-ENTRY CHARTS
// ═══════════════════════════════════════════════════════════

class _HeartRateChart extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _HeartRateChart({required this.vitals});

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();

    final spots = vitals
        .asMap()
        .entries
        .map((e) => fl_chart.FlSpot(e.key.toDouble(), e.value.heartRate))
        .toList();

    final values = vitals.map((v) => v.heartRate).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Heart Rate (bpm)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${vitals.last.heartRate.toStringAsFixed(0)} bpm',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: fl_chart.LineChart(
                fl_chart.LineChartData(
                  minY: min - 5,
                  maxY: max + 5,
                  gridData: fl_chart.FlGridData(
                    show: true,
                    drawVerticalLine: true,
                  ),
                  lineBarsData: [
                    fl_chart.LineChartBarData(
                      spots: spots,
                      color: Colors.red[400],
                      barWidth: 2,
                      belowBarData: fl_chart.BarAreaData(
                        show: true,
                        color: Colors.red[100],
                      ),
                      dotData: const fl_chart.FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Min',
                  value: min.toStringAsFixed(0),
                  unit: 'bpm',
                ),
                _StatItem(
                  label: 'Max',
                  value: max.toStringAsFixed(0),
                  unit: 'bpm',
                ),
                _StatItem(
                  label: 'Avg',
                  value: avg.toStringAsFixed(0),
                  unit: 'bpm',
                ),
                _StatItem(
                  label: 'Readings',
                  value: vitals.length.toString(),
                  unit: '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpO2Chart extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _SpO2Chart({required this.vitals});

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();

    final spots = vitals
        .asMap()
        .entries
        .map((e) => fl_chart.FlSpot(e.key.toDouble(), e.value.spO2))
        .toList();

    final values = vitals.map((v) => v.spO2).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SpO2 (%)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    border: Border.all(color: Colors.green[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${vitals.last.spO2.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: fl_chart.LineChart(
                fl_chart.LineChartData(
                  minY: 90,
                  maxY: 100,
                  gridData: fl_chart.FlGridData(show: true),
                  lineBarsData: [
                    fl_chart.LineChartBarData(
                      spots: spots,
                      color: Colors.green[500],
                      barWidth: 2,
                      belowBarData: fl_chart.BarAreaData(
                        show: true,
                        color: Colors.green[100],
                      ),
                      dotData: const fl_chart.FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Min',
                  value: min.toStringAsFixed(1),
                  unit: '%',
                ),
                _StatItem(
                  label: 'Max',
                  value: max.toStringAsFixed(1),
                  unit: '%',
                ),
                _StatItem(
                  label: 'Avg',
                  value: avg.toStringAsFixed(1),
                  unit: '%',
                ),
                _StatItem(
                  label: 'Readings',
                  value: vitals.length.toString(),
                  unit: '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyTemperatureChart extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _BodyTemperatureChart({required this.vitals});

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();

    final values = vitals.map((v) => v.bodyTemp).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;

    final barGroups = vitals
        .asMap()
        .entries
        .map(
          (e) => fl_chart.BarChartGroupData(
            x: e.key,
            barRods: [
              fl_chart.BarChartRodData(
                toY: e.value.bodyTemp,
                color: Colors.orange[400],
                width: 8,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        )
        .toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Body Temperature (°C)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    border: Border.all(color: Colors.orange[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${vitals.last.bodyTemp.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: fl_chart.BarChart(
                fl_chart.BarChartData(
                  minY: min - 0.5,
                  maxY: max + 0.5,
                  barGroups: barGroups,
                  gridData: fl_chart.FlGridData(show: true),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Min',
                  value: min.toStringAsFixed(1),
                  unit: '°C',
                ),
                _StatItem(
                  label: 'Max',
                  value: max.toStringAsFixed(1),
                  unit: '°C',
                ),
                _StatItem(
                  label: 'Avg',
                  value: avg.toStringAsFixed(1),
                  unit: '°C',
                ),
                _StatItem(
                  label: 'Readings',
                  value: vitals.length.toString(),
                  unit: '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RespiratoryRateChart extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _RespiratoryRateChart({required this.vitals});

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();

    final spots = vitals
        .asMap()
        .entries
        .map((e) => fl_chart.FlSpot(e.key.toDouble(), e.value.respiratoryRate))
        .toList();

    final values = vitals.map((v) => v.respiratoryRate).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Respiratory Rate (rpm)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    border: Border.all(color: Colors.blue[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${vitals.last.respiratoryRate.toStringAsFixed(0)} rpm',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: fl_chart.LineChart(
                fl_chart.LineChartData(
                  minY: min - 2,
                  maxY: max + 2,
                  gridData: fl_chart.FlGridData(show: true),
                  lineBarsData: [
                    fl_chart.LineChartBarData(
                      spots: spots,
                      color: Colors.blue[400],
                      barWidth: 2,
                      dotData: const fl_chart.FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Min',
                  value: min.toStringAsFixed(0),
                  unit: 'rpm',
                ),
                _StatItem(
                  label: 'Max',
                  value: max.toStringAsFixed(0),
                  unit: 'rpm',
                ),
                _StatItem(
                  label: 'Avg',
                  value: avg.toStringAsFixed(0),
                  unit: 'rpm',
                ),
                _StatItem(
                  label: 'Readings',
                  value: vitals.length.toString(),
                  unit: '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodPressureChart extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _BloodPressureChart({required this.vitals});

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();

    final systolicSpots = vitals
        .asMap()
        .entries
        .map((e) => fl_chart.FlSpot(e.key.toDouble(), e.value.systolicBP))
        .toList();

    final diastolicSpots = vitals
        .asMap()
        .entries
        .map((e) => fl_chart.FlSpot(e.key.toDouble(), e.value.diastolicBP))
        .toList();

    final allValues = [
      ...vitals.map((v) => v.systolicBP),
      ...vitals.map((v) => v.diastolicBP),
    ];
    final min = allValues.reduce((a, b) => a < b ? a : b);
    final max = allValues.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Blood Pressure (mmHg)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    border: Border.all(color: Colors.purple[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${vitals.last.systolicBP.toStringAsFixed(0)}/${vitals.last.diastolicBP.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.purple[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: fl_chart.LineChart(
                fl_chart.LineChartData(
                  minY: min - 10,
                  maxY: max + 10,
                  gridData: fl_chart.FlGridData(show: true),
                  lineBarsData: [
                    fl_chart.LineChartBarData(
                      spots: systolicSpots,
                      color: Colors.purple[400],
                      barWidth: 2,
                      dotData: const fl_chart.FlDotData(show: true),
                    ),
                    fl_chart.LineChartBarData(
                      spots: diastolicSpots,
                      color: Colors.purple[200],
                      barWidth: 2,
                      dashArray: [5, 5],
                      dotData: const fl_chart.FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Systolic',
                  value: vitals.last.systolicBP.toStringAsFixed(0),
                  unit: 'mmHg',
                ),
                _StatItem(
                  label: 'Diastolic',
                  value: vitals.last.diastolicBP.toStringAsFixed(0),
                  unit: 'mmHg',
                ),
                _StatItem(
                  label: 'Pulse Pressure',
                  value: (vitals.last.systolicBP - vitals.last.diastolicBP)
                      .toStringAsFixed(0),
                  unit: 'mmHg',
                ),
                _StatItem(
                  label: 'Readings',
                  value: vitals.length.toString(),
                  unit: '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SUMMARY CHARTS
// ═══════════════════════════════════════════════════════════

class _NormalizedMetricsChart extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _NormalizedMetricsChart({required this.vitals});

  double _normalize(double value, double minRef, double maxRef) {
    return ((value - minRef) / (maxRef - minRef)).clamp(0.0, 1.0) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();

    final heartRateMean =
        vitals.map((v) => v.heartRate).reduce((a, b) => a + b) / vitals.length;
    final spo2Mean =
        vitals.map((v) => v.spO2).reduce((a, b) => a + b) / vitals.length;
    final bodyTempMean =
        vitals.map((v) => v.bodyTemp).reduce((a, b) => a + b) / vitals.length;
    final respRateMean =
        vitals.map((v) => v.respiratoryRate).reduce((a, b) => a + b) /
        vitals.length;
    final systolicBPMean =
        vitals.map((v) => v.systolicBP).reduce((a, b) => a + b) / vitals.length;

    final normHR = _normalize(heartRateMean, 40, 160);
    final normSpo2 = _normalize(spo2Mean, 80, 100);
    final normTemp = _normalize(bodyTempMean, 35, 42);
    final normRespRate = _normalize(respRateMean, 8, 30);
    final normBP = _normalize(systolicBPMean, 80, 180);

    final barGroups = [
      fl_chart.BarChartGroupData(
        x: 0,
        barRods: [
          fl_chart.BarChartRodData(
            toY: normHR,
            color: Colors.red[400],
            width: 20,
          ),
        ],
      ),
      fl_chart.BarChartGroupData(
        x: 1,
        barRods: [
          fl_chart.BarChartRodData(
            toY: normSpo2,
            color: Colors.green[500],
            width: 20,
          ),
        ],
      ),
      fl_chart.BarChartGroupData(
        x: 2,
        barRods: [
          fl_chart.BarChartRodData(
            toY: normTemp,
            color: Colors.orange[400],
            width: 20,
          ),
        ],
      ),
      fl_chart.BarChartGroupData(
        x: 3,
        barRods: [
          fl_chart.BarChartRodData(
            toY: normRespRate,
            color: Colors.blue[400],
            width: 20,
          ),
        ],
      ),
      fl_chart.BarChartGroupData(
        x: 4,
        barRods: [
          fl_chart.BarChartRodData(
            toY: normBP,
            color: Colors.purple[400],
            width: 20,
          ),
        ],
      ),
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Normalized Metrics (Clinical Range)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: fl_chart.BarChart(
                fl_chart.BarChartData(
                  maxY: 100,
                  barGroups: barGroups,
                  gridData: fl_chart.FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpO2GaugeChart extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _SpO2GaugeChart({required this.vitals});

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();

    final meanSpo2 =
        vitals.map((v) => v.spO2).reduce((a, b) => a + b) / vitals.length;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SpO2 Gauge (Mean)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                constraints: BoxConstraints(maxHeight: 160, maxWidth: 160),
                child: fl_chart.PieChart(
                  fl_chart.PieChartData(
                    sections: [
                      fl_chart.PieChartSectionData(
                        value: meanSpo2,
                        color: Colors.green[500],
                        radius: 45,
                      ),
                      fl_chart.PieChartSectionData(
                        value: 100 - meanSpo2,
                        color: Colors.grey[200],
                        radius: 45,
                      ),
                    ],
                    centerSpaceRadius: 35,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: meanSpo2.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                    TextSpan(
                      text: '%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartRateHistogram extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _HeartRateHistogram({required this.vitals});

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();

    final below60 = vitals.where((v) => v.heartRate < 60).length;
    final range60to80 = vitals
        .where((v) => v.heartRate >= 60 && v.heartRate < 80)
        .length;
    final range80to100 = vitals
        .where((v) => v.heartRate >= 80 && v.heartRate < 100)
        .length;
    final above100 = vitals.where((v) => v.heartRate >= 100).length;

    final barGroups = [
      fl_chart.BarChartGroupData(
        x: 0,
        barRods: [
          fl_chart.BarChartRodData(
            toY: below60.toDouble(),
            color: Colors.blue[300],
            width: 20,
          ),
        ],
      ),
      fl_chart.BarChartGroupData(
        x: 1,
        barRods: [
          fl_chart.BarChartRodData(
            toY: range60to80.toDouble(),
            color: Colors.blue[500],
            width: 20,
          ),
        ],
      ),
      fl_chart.BarChartGroupData(
        x: 2,
        barRods: [
          fl_chart.BarChartRodData(
            toY: range80to100.toDouble(),
            color: Colors.orange[400],
            width: 20,
          ),
        ],
      ),
      fl_chart.BarChartGroupData(
        x: 3,
        barRods: [
          fl_chart.BarChartRodData(
            toY: above100.toDouble(),
            color: Colors.red[400],
            width: 20,
          ),
        ],
      ),
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Heart Rate Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: fl_chart.BarChart(
                fl_chart.BarChartData(
                  maxY: (vitals.length / 2).toDouble(),
                  barGroups: barGroups,
                  gridData: fl_chart.FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodPressureGroupedChart extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _BloodPressureGroupedChart({required this.vitals});

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();

    final barGroups = vitals
        .asMap()
        .entries
        .map(
          (e) => fl_chart.BarChartGroupData(
            x: e.key,
            barRods: [
              fl_chart.BarChartRodData(
                toY: e.value.systolicBP,
                color: Colors.purple[400],
                width: 6,
              ),
              fl_chart.BarChartRodData(
                toY: e.value.diastolicBP,
                color: Colors.purple[200],
                width: 6,
              ),
            ],
          ),
        )
        .toList();

    final allValues = [
      ...vitals.map((v) => v.systolicBP),
      ...vitals.map((v) => v.diastolicBP),
    ];
    final maxY = allValues.reduce((a, b) => a > b ? a : b) + 10;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Blood Pressure Over Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              width: double.infinity,
              child: fl_chart.BarChart(
                fl_chart.BarChartData(
                  maxY: maxY,
                  barGroups: barGroups,
                  gridData: fl_chart.FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.purple[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Systolic', style: TextStyle(fontSize: 11)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.purple[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Diastolic', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

class _HistoryData {
  final List<VitalDataModel> vitals;

  const _HistoryData({required this.vitals});
  const _HistoryData.empty() : vitals = const [];
}
