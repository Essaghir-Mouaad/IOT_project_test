import 'package:flutter/material.dart';

class OverallHealth extends StatelessWidget {
  final String title;
  final String status;

  const OverallHealth({super.key, required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Text(
      "Your $title currently indicates: $status\n status",
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: status.toLowerCase() == "normal"
            ? Colors.green
            : status.toLowerCase() == "warning"
            ? Colors.orange
            : Colors.red,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
