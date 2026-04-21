import 'package:brew_crew/shared/wave_line.dart';
import 'package:flutter/material.dart';

class PredictionContainer extends StatelessWidget {
  final double value;
  final Icon icon;
  final Color color;
  final String unite;
  const PredictionContainer({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    required this.unite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(4.0),
      ),
      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8.0),
          WaveLine(color: color),
          const SizedBox(width: 8.0),
          Text(
            "${value.toString()} $unite",
            style: TextStyle(
              color: color,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
