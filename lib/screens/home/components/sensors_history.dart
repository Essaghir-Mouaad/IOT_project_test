import 'dart:math' as math;

import 'package:brew_crew/models/sensor_model.dart';
import 'package:brew_crew/models/vital_data_model.dart';
import 'package:brew_crew/services/database.dart';
import 'package:brew_crew/shared/loading.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:flutter/material.dart';

class SensorsHistory extends StatefulWidget {
  final String deviceId;
  final DatabaseService db;

  const SensorsHistory({
    super.key,
    required this.deviceId,
    required this.db,
  });

  @override
  State<SensorsHistory> createState() => _SensorsHistoryState();
}

class _SensorsHistoryState extends State<SensorsHistory> {
  late Future<_HistoryData> _historyFuture;
  bool _hasSeededInSession = false;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<_HistoryData> _loadHistory() async {
    if (!_hasSeededInSession) {
      final hasSensorData = await widget.db.hasDeviceSensorData(widget.deviceId);
      if (!hasSensorData) {
        await _seedSensorsOnceForDevice();
      }
      _hasSeededInSession = true;
    }

    final sensors = await _fetchAllSensorsHistory();
    final vitals = await _fetchVitalsHistory();
    return _HistoryData(vitals: vitals, sensors: sensors);
  }

  Future<List<VitalDataModel>> _fetchVitalsHistory() async {
    final raw = await widget.db.getVitalsHistory(widget.deviceId, limit: 120);
    return raw
        .asMap()
        .entries
        .map((entry) => VitalDataModel.fromMap('hist_${entry.key}', entry.value))
        .toList();
  }

  Future<void> _seedSensorsOnceForDevice() async {
    try {
      final random = math.Random(widget.deviceId.hashCode);

      // Generate starter history for sensors only if device has no sensor history yet.
      for (int sensorNum = 1; sensorNum <= 6; sensorNum++) {
        final baseValue = 18.0 + (sensorNum * 4.0);

        for (int i = 0; i < 50; i++) {
          final timeVariation = (i / 50.0) * math.pi;
          final trend = math.sin(timeVariation) * 2.6;
          final noise = (random.nextDouble() - 0.5) * 1.8;
          final value = baseValue + trend + noise;

          await widget.db.addSensorReading(
            widget.deviceId,
            sensorNum,
            {
              'value': value.clamp(0.0, 100.0),
              'unit': sensorNum % 2 == 0 ? '°C' : '%',
              'status': 'online',
              'label': _getSensorLabel(sensorNum),
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error generating random data: $e');
    }
  }

  String _getSensorLabel(int sensorNum) {
    final labels = [
      'Temperature',
      'Humidity',
      'Air Quality',
      'Pressure',
      'Light Level',
      'Motion'
    ];
    return labels[sensorNum - 1];
  }

  Future<Map<int, List<SensorModel>>> _fetchAllSensorsHistory() async {
    final result = <int, List<SensorModel>>{};

    for (int i = 1; i <= 6; i++) {
      try {
        final history = await widget.db.getSensorHistory(
          widget.deviceId,
          i,
          limit: 100,
        );
        result[i] = history
            .map((data) => SensorModel.fromMap(i, data))
            .toList();
      } catch (e) {
        result[i] = [];
      }
    }

    return result;
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
        final sensorsData = historyData.sensors;
        final vitalsData = historyData.vitals;

        if (sensorsData.isEmpty ||
            sensorsData.values.every((list) => list.isEmpty)) {
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
                    'No sensor data available',
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(title: 'Vitals History'),
                  const SizedBox(height: 8),
                  _VitalsHistorySection(vitals: vitalsData),
                  const SizedBox(height: 16),
                  const _SectionHeader(title: 'Sensors History'),
                  const SizedBox(height: 8),
                  for (int i = 1; i <= 6; i++) ...[
                    _SensorHistoryCard(
                      sensorNumber: i,
                      sensorData: sensorsData[i] ?? [],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SensorHistoryCard extends StatelessWidget {
  final int sensorNumber;
  final List<SensorModel> sensorData;

  const _SensorHistoryCard({
    required this.sensorNumber,
    required this.sensorData,
  });

  List<fl_chart.FlSpot> _generateChartData() {
    if (sensorData.isEmpty) return [];

    return sensorData.asMap().entries.map((e) {
      return fl_chart.FlSpot(e.key.toDouble(), e.value.value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _generateChartData();
    final hasData = chartData.isNotEmpty;

    // Get latest value and unit
    final latestSensor =
        sensorData.isNotEmpty ? sensorData.last : null;
    final unit = latestSensor?.unit ?? 'N/A';
    final latestValue = latestSensor?.value ?? 0;

    // Calculate min and max for chart
    double minY = 0, maxY = 100;
    if (hasData) {
      final yValues = chartData.map((e) => e.y).toList();
      minY = yValues.reduce((a, b) => a < b ? a : b) - 5;
      maxY = yValues.reduce((a, b) => a > b ? a : b) + 5;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sensor $sensorNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (latestSensor?.label != null)
                      Text(
                        latestSensor!.label!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        latestValue.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (hasData)
              SizedBox(
                height: 200,
                child: fl_chart.LineChart(
                  fl_chart.LineChartData(
                    gridData: fl_chart.FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (maxY - minY) / 5,
                      getDrawingHorizontalLine: (value) {
                        return fl_chart.FlLine(
                          color: Colors.grey[200],
                          strokeWidth: 0.5,
                        );
                      },
                    ),
                    titlesData: fl_chart.FlTitlesData(
                      show: true,
                      bottomTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: (chartData.length / 5).ceil().toDouble(),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < chartData.length) {
                              return Text(
                                index.toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(showTitles: false),
                      ),
                      rightTitles: const fl_chart.AxisTitles(
                        sideTitles: fl_chart.SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: fl_chart.FlBorderData(show: true),
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      fl_chart.LineChartBarData(
                        spots: chartData,
                        isCurved: true,
                        dotData: fl_chart.FlDotData(
                          show: chartData.length <= 20,
                        ),
                        belowBarData: fl_chart.BarAreaData(
                          show: true,
                          color: Colors.blue.withValues(alpha: 0.1),
                        ),
                        color: Colors.blue[600],
                        barWidth: 2,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'No data yet',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),

            if (hasData) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'Min',
                    value: chartData
                        .map((e) => e.y)
                        .reduce((a, b) => a < b ? a : b)
                        .toStringAsFixed(1),
                    unit: unit,
                  ),
                  _StatItem(
                    label: 'Max',
                    value: chartData
                        .map((e) => e.y)
                        .reduce((a, b) => a > b ? a : b)
                        .toStringAsFixed(1),
                    unit: unit,
                  ),
                  _StatItem(
                    label: 'Avg',
                    value: (chartData.fold(0.0, (sum, e) => sum + e.y) /
                            chartData.length)
                        .toStringAsFixed(1),
                    unit: unit,
                  ),
                  _StatItem(
                    label: 'Readings',
                    value: chartData.length.toString(),
                    unit: '',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VitalsHistorySection extends StatelessWidget {
  final List<VitalDataModel> vitals;

  const _VitalsHistorySection({required this.vitals});

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('No vitals history found for this device yet.'),
      );
    }

    return Column(
      children: [
        _MetricHistoryCard(
          title: 'Heart Rate',
          unit: 'bpm',
          color: Colors.red,
          values: vitals.map((v) => v.heartRate).toList(),
        ),
        const SizedBox(height: 12),
        _MetricHistoryCard(
          title: 'SpO2',
          unit: '%',
          color: Colors.green,
          values: vitals.map((v) => v.spO2).toList(),
        ),
        const SizedBox(height: 12),
        _MetricHistoryCard(
          title: 'Body Temperature',
          unit: '°C',
          color: Colors.orange,
          values: vitals.map((v) => v.bodyTemp).toList(),
        ),
        const SizedBox(height: 12),
        _MetricHistoryCard(
          title: 'Respiratory Rate',
          unit: 'rpm',
          color: Colors.blue,
          values: vitals.map((v) => v.respiratoryRate).toList(),
        ),
      ],
    );
  }
}

class _MetricHistoryCard extends StatelessWidget {
  final String title;
  final String unit;
  final Color color;
  final List<double> values;

  const _MetricHistoryCard({
    required this.title,
    required this.unit,
    required this.color,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final spots = values
        .asMap()
        .entries
        .map((e) => fl_chart.FlSpot(e.key.toDouble(), e.value))
        .toList();

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final minY = min - 2;
    final maxY = max + 2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title ($unit)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: fl_chart.LineChart(
                fl_chart.LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: fl_chart.FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const fl_chart.FlTitlesData(
                    topTitles: fl_chart.AxisTitles(sideTitles: fl_chart.SideTitles(showTitles: false)),
                    rightTitles: fl_chart.AxisTitles(sideTitles: fl_chart.SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    fl_chart.LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: fl_chart.FlDotData(show: spots.length <= 30),
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _HistoryData {
  final List<VitalDataModel> vitals;
  final Map<int, List<SensorModel>> sensors;

  const _HistoryData({required this.vitals, required this.sensors});
  const _HistoryData.empty()
      : vitals = const [],
        sensors = const {};
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
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
