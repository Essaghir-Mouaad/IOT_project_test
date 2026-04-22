import 'package:flutter/material.dart';
import 'status_card.dart';
import 'theme_colors.dart';

// ── Normal card ──────────────────────────────────────────
class NormalCard extends StatefulWidget {
  const NormalCard({super.key});
  @override
  State<NormalCard> createState() => _NormalCardState();
}

class _NormalCardState extends State<NormalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bob;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bob = Tween(
      begin: 0.0,
      end: -8.0,
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
      color: StatusColors.normalPrimary,
      bgColor: StatusColors.normalBg,
      badge: 'All clear',
      title: 'Everything looks good',
      subtitle: 'No anomalies detected. Operating within normal parameters.',
      child: AnimatedBuilder(
        animation: _bob,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _bob.value),
          child: CustomPaint(
            size: const Size(100, 100),
            painter: _NormalFacePainter(),
          ),
        ),
      ),
    );
  }
}

class _NormalFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final paint = Paint()
      ..color = StatusColors.normalPrimary
      ..style = PaintingStyle.fill;

    // face
    canvas.drawCircle(
      Offset(cx, cy),
      PainterDimensions.normalFaceRadius,
      Paint()..color = StatusColors.normalBg,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      PainterDimensions.normalFaceRadius,
      Paint()
        ..color = StatusColors.normalAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // eyes
    canvas.drawCircle(
      Offset(cx - 13, cy - 10),
      PainterDimensions.normalEyeRadius,
      paint..color = StatusColors.normalDark,
    );
    canvas.drawCircle(
      Offset(cx + 13, cy - 10),
      PainterDimensions.normalEyeRadius,
      paint,
    );

    // smile
    final smile = Path()
      ..moveTo(cx - 17, cy + PainterDimensions.normalSmileOffset)
      ..quadraticBezierTo(
        cx,
        cy + 26,
        cx + 17,
        cy + PainterDimensions.normalSmileOffset,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = StatusColors.normalDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
