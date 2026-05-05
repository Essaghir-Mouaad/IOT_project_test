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
    required String activity,
  }) {
    if (hr == 0 || spo2 == 0 || temp == 0 || age == 0) return;

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
        activity: activity,
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
    required String activity,
    required int age,
  }) {
    return Column(
      children: [
        Row(
          children: [
            _VitalCard(
              label: 'Age',
              value: age.toString(),
              unit: Icon(
                Icons.person,
                size: 16,
                color: const Color.fromARGB(255, 209, 12, 248),
              ),
              color: const Color.fromARGB(255, 174, 0, 255),
              fillFraction: (temp.clamp(35, 42) - 35) / 7,
            ),
            const SizedBox(width: 8),
            _VitalCard(
              label: 'Body temp',
              value: temp.toStringAsFixed(1),
              unit: Icon(
                Icons.thermostat,
                size: 16,
                color: const Color(0xFFEF9F27),
              ),
              color: const Color(0xFFEF9F27),
              fillFraction: (temp.clamp(35, 42) - 35) / 7,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _VitalCard(
              label: 'SpO₂',
              value: spo2.toStringAsFixed(0),
              unit: Icon(
                Icons.opacity_outlined,
                size: 16,
                color: const Color(0xFF378ADD),
              ),
              color: const Color(0xFF378ADD),
              fillFraction: (spo2.clamp(80, 100) - 80) / 20,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _VitalCard(
              label: 'Heart rate',
              value: hr.toStringAsFixed(0),
              unit: Icon(
                Icons.fitness_center,
                size: 16,
                color: const Color(0xFFE24B4A),
              ),
              color: const Color(0xFFE24B4A),
              fillFraction: (hr.clamp(40, 180) - 40) / 140,
            ),
            const SizedBox(width: 8),
            _VitalCard(
              label: 'Activity',
              value: activity,
              unit: Icon(
                Icons.directions_run_outlined,
                size: 16,
                color: const Color(0xFF6FEC09),
              ),
              color: const Color.fromARGB(255, 111, 236, 9),
              fillFraction: (hr.clamp(40, 180) - 40) / 140,
            ),
          ],
        ),
      ],
    );
  }

  // ── Disclaimer ────────────────────────────────────────

  Widget _disclaimer() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF9F27).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: Color(0xFFBA7517),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'This prediction is generated by an AI model and is not a definitive medical diagnosis. Always consult a healthcare professional for accurate assessment and advice. and please for case of emergency call 15 or your local emergency number immediately. then check the location of your patient and provide it to the emergency operator.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF854F0B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
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
              final activity = (raw['activity'] ?? 'Sitting').toString();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _triggerPrediction(
                  age: age,
                  hr: hr,
                  spo2: spo2,
                  temp: temp,
                  activity: activity,
                );
              });

              return FutureBuilder<int>(
                future: _predictionFuture,
                builder: (context, predSnap) {
                  if (_predictionFuture == null ||
                      predSnap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text('Waiting for vitals data...'),
                        ],
                      ),
                    );
                  }

                  if (predSnap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Prediction failed: ${predSnap.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _predictionFuture = _mlServices.predict(
                                  age: age,
                                  hr: hr,
                                  spo2: spo2,
                                  temp: temp,
                                  activity: 'Sitting',
                                );
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final alert = _alertFromCode(predSnap.data!);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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

                        _vitalsGrid(
                          hr: hr,
                          temp: temp,
                          spo2: spo2,
                          age: age,
                          activity: activity,
                        ),

                        const SizedBox(height: 20),

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

                        _disclaimer(),
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
  final String label, value;
  final Icon unit;
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
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.52),
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
                unit,
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: fillFraction.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: color.withValues(alpha: 0.22),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
