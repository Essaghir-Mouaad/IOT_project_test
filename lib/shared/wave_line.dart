import 'dart:math';
import 'package:flutter/material.dart';

class WaveLine extends StatelessWidget {
  const WaveLine({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(150, 50), painter: WavePainter());
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (double x = 0; x <= size.width; x += 1.0) {
      final y = size.height / 2 + 3 * sin(x / size.width * 20 * pi);
      x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    final double lastX = size.width;
    final double lastY = size.height / 2 + 30 * sin(2 * pi);
    const double arrowSize = 7.0;

    final arrowPath = Path();
    arrowPath.moveTo(lastX, lastY);
    arrowPath.lineTo(lastX - arrowSize, lastY - arrowSize);
    arrowPath.moveTo(lastX, lastY);
    arrowPath.lineTo(lastX - arrowSize, lastY + arrowSize);

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
