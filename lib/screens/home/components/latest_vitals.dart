import 'package:brew_crew/shared/vitals_container.dart';
import 'package:flutter/material.dart';

class LatestVitals extends StatelessWidget {
  final double heart;
  final double temperature;
  final double spo2;
  final double airQuality; // Placeholder for air quality index

  const LatestVitals({
    super.key,
    required this.heart,
    required this.temperature,
    required this.spo2,
    required this.airQuality,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.stretch,
        // mainAxisAlignment: MainAxisAlignment.start,
        children: [
          VitalsContainer(
            info: heart,
            unit: 'bpm',
            icon: Icons.favorite,
            label: "Heart Rate",
            color: Colors.red,
          ),
          const SizedBox(height: 2),
          VitalsContainer(
            info: temperature,
            unit: '°C',
            icon: Icons.thermostat,
            label: "Temperature",
            color: Colors.blue,
          ),
          const SizedBox(height: 2),
          VitalsContainer(
            info: spo2,
            unit: '%',
            icon: Icons.brightness_5,
            label: "SpO2",
            color: Colors.green,
          ),
          const SizedBox(height: 2),
          VitalsContainer(
            info: airQuality,
            unit: 'AQI',
            icon: Icons.air,
            label: "Air Quality",
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}
