import 'package:brew_crew/screens/home/components/prediction_compo/critical_stat.dart';
import 'package:brew_crew/screens/home/components/prediction_compo/normal_stat.dart';
import 'package:brew_crew/screens/home/components/prediction_compo/warning_stat.dart';
import 'package:brew_crew/services/database.dart';
import 'package:brew_crew/services/ml_services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Predictions extends StatefulWidget {
  final String deviceId;
  final DatabaseService db;

  const Predictions({super.key, required this.deviceId, required this.db});

  @override
  State<Predictions> createState() => _PredictionsState();
}

class _PredictionsState extends State<Predictions> {
  final MlServices _mlServices = MlServices();
  Future<int>? _predictionFuture;

  double? _lastHr, _lastSpo2, _lastTemp;
  int? _lastAge;

  void _triggerPrediction({
    required int age,
    required double hr,
    required double spo2,
    required double temp,
  }) {
    if (hr == _lastHr &&
        spo2 == _lastSpo2 &&
        temp == _lastTemp &&
        age == _lastAge)
      return;

    _lastHr = hr;
    _lastSpo2 = spo2;
    _lastTemp = temp;
    _lastAge = age;

    setState(() {
      _predictionFuture = _mlServices.predict(
        age: age,
        hr: hr,
        spo2: spo2,
        temp: temp,
        activity: 'Sitting',
      );
    });
  }

  String _alertFromCode(int code) {
    switch (code) {
      case 0:
        return 'critical';
      case 1:
        return 'warning';
      case 2:
        return 'normal';
      default:
        return 'normal';
    }
  }

  // ── App Bar ───────────────────────────────────────────

  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      title: const Text(
        'Health Predictions',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
    );
  }

  // ── Vitals Row ────────────────────────────────────────

  Widget _vitalsGrid({
    required double hr,
    required double temp,
    required double spo2,
  }) {
    return Row(
      children: [
        _VitalCard(
          label: 'Heart rate',
          value: hr.toStringAsFixed(0),
          unit: 'bpm',
          color: const Color(0xFFE24B4A),
          fillFraction: (hr.clamp(40, 180) - 40) / 140,
        ),
        const SizedBox(width: 8),
        _VitalCard(
          label: 'Body temp',
          value: temp.toStringAsFixed(1),
          unit: '°C',
          color: const Color(0xFFEF9F27),
          fillFraction: (temp.clamp(35, 42) - 35) / 7,
        ),
        const SizedBox(width: 8),
        _VitalCard(
          label: 'SpO₂',
          value: spo2.toStringAsFixed(0),
          unit: '%',
          color: const Color(0xFF378ADD),
          fillFraction: (spo2.clamp(80, 100) - 80) / 20,
        ),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────

  Widget _body() {
    return Container(
      color: Colors.transparent,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: widget.db.getUserProfile(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final age = ((userSnap.data ?? {})['age'] ?? 0) as int;

          return StreamBuilder<DatabaseEvent>(
            stream: widget.db.latestVitalsStream(widget.deviceId),
            builder: (context, vitalsSnap) {
              if (!vitalsSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final raw = Map<String, dynamic>.from(
                vitalsSnap.data!.snapshot.value as Map,
              );

              final hr = (raw['heartRate'] ?? 0).toDouble();
              final spo2 = (raw['spo2'] ?? 0).toDouble();
              final temp = (raw['bodyTemp'] ?? 0).toDouble();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _triggerPrediction(age: age, hr: hr, spo2: spo2, temp: temp);
              });

              return FutureBuilder<int>(
                future: _predictionFuture,
                builder: (context, predSnap) {
                  if (_predictionFuture == null ||
                      predSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (predSnap.hasError) {
                    return Center(
                      child: Text(
                        'Prediction failed: ${predSnap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }

                  final alert = _alertFromCode(predSnap.data!);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section label
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'CURRENT VITALS',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),

                        _vitalsGrid(hr: hr, temp: temp, spo2: spo2),

                        const SizedBox(height: 20),

                        // Section label
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'AI ASSESSMENT',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),

                        if (alert == 'critical')
                          CriticalCard()
                        else if (alert == 'warning')
                          WarningCard()
                        else
                          NormalCard(),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _appBar(),
      body: _body(),
    );
  }
}

// ── Vital metric card ────────────────────────────────────

class _VitalCard extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  final double fillFraction;

  const _VitalCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.fillFraction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: fillFraction.clamp(0.0, 1.0),
                minHeight: 2,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
