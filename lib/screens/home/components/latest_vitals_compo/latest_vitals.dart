import 'package:brew_crew/shared/vitals_container.dart';
import 'package:flutter/material.dart';

class LatestVitals extends StatelessWidget {
  final double heart;
  final double temperature;
  final double spo2;
  final double airQuality;

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   'Latest Vitals',
          //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
          //     fontWeight: FontWeight.w600,
          //     letterSpacing: -0.3,
          //   ),
          // ),
          // const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: VitalsContainer(
                  info: heart,
                  icon: Icons.favorite_rounded,
                  unit: 'bpm',
                  color: const Color.fromARGB(255, 209, 16, 16),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: VitalsContainer(
                  info: temperature,
                  icon: Icons.thermostat_rounded,
                  unit: '°C',
                  color: const Color.fromARGB(255, 230, 119, 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: VitalsContainer(
                  info: spo2,
                  icon: Icons.water_drop_rounded,
                  unit: '%',
                  color: const Color.fromARGB(255, 0, 111, 255),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: VitalsContainer(
                  info: airQuality,
                  icon: Icons.air_rounded,
                  unit: 'AQI',
                  color: const Color.fromARGB(255, 6, 196, 94),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
