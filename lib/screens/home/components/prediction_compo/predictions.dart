// import 'package:brew_crew/services/database.dart';
import 'package:brew_crew/screens/home/components/prediction_compo/critical_stat.dart';
import 'package:brew_crew/screens/home/components/prediction_compo/normal_stat.dart';
import 'package:brew_crew/screens/home/components/prediction_compo/warning_stat.dart';
import 'package:brew_crew/shared/prediction_container.dart';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Predictions extends StatefulWidget {
  final String deviceId;
  // final Database db;
  final String alert;
  const Predictions({super.key, required this.deviceId, required this.alert});

  @override
  State<Predictions> createState() => _PredictionsState();
}

class _PredictionsState extends State<Predictions> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _appBar(), body: _body());
  }

  // ----------------------
  // App Bar
  // ----------------------

  PreferredSizeWidget _appBar() {
    return AppBar(
      title: const Text('Predictions'),
      titleTextStyle: const TextStyle(
        color: Colors.blue,
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
      centerTitle: true,
      backgroundColor: Colors.blue.withValues(alpha: .07),
    );
  }

  // ----------------------
  // Body
  // ----------------------

  Widget _body() {
    return Container(
      color: Colors.blue.withValues(alpha: .03),
      padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
      child: Column(
        children: [
          PredictionContainer(
            icon: Icon(Icons.heart_broken, color: Colors.red, size: 40.0),
            value: 23.4,
            color: Colors.red,
            unite: "bp",
          ),
          PredictionContainer(
            icon: Icon(Icons.thermostat, color: Colors.orange, size: 40.0),
            value: 23.4,
            color: Colors.orange,
            unite: "°C",
          ),
          PredictionContainer(
            icon: Icon(Icons.brightness_5, color: Colors.blue, size: 40.0),
            value: 23.4,
            color: Colors.blue,
            unite: "%",
          ),

          const SizedBox(height: 20.0),
          Text(
            "Model Predictions",
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 30.0,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.normal,
            ),
          ),

          const SizedBox(height: 20.0),

          widget.alert == "critical"
              ? CriticalCard()
              : widget.alert == "warning"
              ? WarningCard()
              : NormalCard(),
        ],
      ),
    );
  }
}
