// ── Critical card ────────────────────────────────────────
import 'package:flutter/material.dart';
import 'status_card.dart';
import 'theme_colors.dart';

class CriticalCard extends StatefulWidget {
  const CriticalCard({super.key});
  @override
  State<CriticalCard> createState() => _CriticalCardState();
}

class _CriticalCardState extends State<CriticalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (a, b) => Transform.scale(
        scale: 1.0 + _ctrl.value * 0.03,
        child: StatusCard(
          color: StatusColors.criticalPrimary,
          bgColor: StatusColors.criticalBg,
          badge: 'Critical',
          title: 'Critical — immediate action',
          subtitle: 'Severe anomaly detected. Escalate now.',
          child: CustomPaint(
            size: const Size(100, 100),
            painter: _CriticalFacePainter(_ctrl.value),
          ),
        ),
      ),
    );
  }
}

class _CriticalFacePainter extends CustomPainter {
  final double t;
  _CriticalFacePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2 - 4;
    final red = StatusColors.criticalPrimary;
    final dark = StatusColors.criticalDark;

    canvas.drawCircle(
      Offset(cx, cy),
      PainterDimensions.criticalFaceRadius,
      Paint()..color = StatusColors.criticalBg,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      PainterDimensions.criticalFaceRadius,
      Paint()
        ..color = red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      Offset(cx - 12, cy - 6),
      PainterDimensions.criticalEyeRadius,
      Paint()..color = dark,
    );
    canvas.drawCircle(
      Offset(cx + 12, cy - 6),
      PainterDimensions.criticalEyeRadius,
      Paint()..color = dark,
    );

    // X eyes
    final xp = Paint()
      ..color = red
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 17, cy - 11), Offset(cx - 7, cy - 1), xp);
    canvas.drawLine(Offset(cx - 7, cy - 11), Offset(cx - 17, cy - 1), xp);
    canvas.drawLine(Offset(cx + 7, cy - 11), Offset(cx + 17, cy - 1), xp);
    canvas.drawLine(Offset(cx + 17, cy - 11), Offset(cx + 7, cy - 1), xp);

    final frown = Path()
      ..moveTo(cx - 15, cy + 18)
      ..quadraticBezierTo(cx, cy + 10, cx + 15, cy + 18);
    canvas.drawPath(
      frown,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // ambulance body
    final ambY = size.height - 18.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          2,
          ambY - 10,
          PainterDimensions.criticalAmbulanceWidth,
          PainterDimensions.criticalAmbulanceHeight,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = red,
    );
    // siren blink
    final sirenColor = Color.lerp(red, StatusColors.criticalSiren, t)!;
    canvas.drawRect(
      Rect.fromLTWH(
        6,
        ambY - 18,
        PainterDimensions.criticalSirenWidth,
        PainterDimensions.criticalSirenHeight,
      ),
      Paint()..color = sirenColor,
    );

    canvas.drawCircle(
      Offset(16, ambY + 8),
      PainterDimensions.criticalWheelRadius,
      Paint()..color = StatusColors.wheelDark,
    );
    canvas.drawCircle(
      Offset(16, ambY + 8),
      PainterDimensions.criticalWheelCenterRadius,
      Paint()..color = StatusColors.wheelGrey,
    );
    canvas.drawCircle(
      Offset(84, ambY + 8),
      PainterDimensions.criticalWheelRadius,
      Paint()..color = StatusColors.wheelDark,
    );
    canvas.drawCircle(
      Offset(84, ambY + 8),
      PainterDimensions.criticalWheelCenterRadius,
      Paint()..color = StatusColors.wheelGrey,
    );
  }

  @override
  bool shouldRepaint(_CriticalFacePainter old) => old.t != t;
}
