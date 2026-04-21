// ── Warning card ─────────────────────────────────────────
import 'package:flutter/material.dart';
import 'status_card.dart';
import 'theme_colors.dart';

class WarningCard extends StatefulWidget {
  const WarningCard({super.key});
  @override
  State<WarningCard> createState() => _WarningCardState();
}

class _WarningCardState extends State<WarningCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _swing;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _swing = Tween(
      begin: -0.22,
      end: 0.22,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatusCard(
      color: StatusColors.warningPrimary,
      bgColor: StatusColors.warningBg,
      badge: 'Warning',
      title: 'Unusual pattern detected',
      subtitle: 'Values outside expected range. Review recommended soon.',
      child: AnimatedBuilder(
        animation: _swing,
        builder: (_, __) => CustomPaint(
          size: const Size(100, 110),
          painter: _WarningFacePainter(_swing.value),
        ),
      ),
    );
  }
}

class _WarningFacePainter extends CustomPainter {
  final double handsAngle;
  _WarningFacePainter(this.handsAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2 + 8;
    final amber = StatusColors.warningAccent;
    final dark = StatusColors.warningDark;

    canvas.drawCircle(
      Offset(cx, cy),
      PainterDimensions.warningFaceRadius,
      Paint()..color = StatusColors.warningBg,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      PainterDimensions.warningFaceRadius,
      Paint()
        ..color = amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      Offset(cx - 13, cy - 8),
      PainterDimensions.warningEyeRadius,
      Paint()..color = dark,
    );
    canvas.drawCircle(
      Offset(cx + 13, cy - 8),
      PainterDimensions.warningEyeRadius,
      Paint()..color = dark,
    );

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

    // hands on head (animated)
    canvas.save();
    canvas.translate(cx, cy - 38);
    canvas.rotate(handsAngle);
    final handPaint = Paint()
      ..color = amber
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(-25, 0),
      Offset(0, PainterDimensions.warningHandsEndY),
      handPaint,
    );
    canvas.drawLine(
      const Offset(25, 0),
      Offset(0, PainterDimensions.warningHandsEndY),
      handPaint,
    );
    canvas.drawCircle(
      Offset(-PainterDimensions.warningHandsHeadX, 0),
      PainterDimensions.warningHandsHeadRadius,
      Paint()
        ..color = StatusColors.warningBg
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(-PainterDimensions.warningHandsHeadX, 0),
      PainterDimensions.warningHandsHeadRadius,
      Paint()
        ..color = amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(PainterDimensions.warningHandsHeadX, 0),
      PainterDimensions.warningHandsHeadRadius,
      Paint()
        ..color = StatusColors.warningBg
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(PainterDimensions.warningHandsHeadX, 0),
      PainterDimensions.warningHandsHeadRadius,
      Paint()
        ..color = amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WarningFacePainter old) => old.handsAngle != handsAngle;
}
