import 'package:brew_crew/shared/virtal_column.dart';
import 'package:flutter/material.dart';

class VitalsContainer extends StatelessWidget {
  final double info;
  final IconData icon;
  final String label;
  final Color color;
  final String unit;

  const VitalsContainer({
    super.key,
    required this.info,
    required this.icon,
    required this.label,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return VitalItem(
      icon: icon,
      unit: unit,
      color: color,
      label: label,
      value: info.toStringAsFixed(1),
    );
  }
}
