// ── Critical card ────────────────────────────────────────
import 'package:flutter/material.dart';
import 'status_card.dart';
import 'theme_colors.dart';

class CriticalCard extends StatefulWidget {
  final VoidCallback? onEscalate;
  const CriticalCard({super.key, this.onEscalate});

  @override
  State<CriticalCard> createState() => _CriticalCardState();
}

class _CriticalCardState extends State<CriticalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => StatusCard(
        color: StatusColors.criticalPrimary,
        bgColor: StatusColors.criticalBg,
        darkColor: StatusColors.criticalDark,
        badge: 'Critical',
        title: 'Immediate action required',
        subtitle: 'Severe anomaly detected across multiple vitals. Escalate to clinical staff now.',
        actionLabel: 'Escalate now',
        onAction: widget.onEscalate,
        icon: CustomPaint(
          size: const Size(32, 32),
          painter: _CriticalIconPainter(_pulse.value),
        ),
      ),
    );
  }
}

class _CriticalIconPainter extends CustomPainter {
  final double t;
  _CriticalIconPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final red = StatusColors.criticalPrimary;
    final dark = StatusColors.criticalDark;

    // Face circle
    canvas.drawCircle(Offset(cx, cy), 13,
        Paint()..color = StatusColors.criticalBg);
    canvas.drawCircle(
      Offset(cx, cy),
      13,
      Paint()
        ..color = Color.lerp(red, dark, t * 0.3)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // X eyes
    final xp = Paint()
      ..color = red
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 7, cy - 5), Offset(cx - 3, cy - 1), xp);
    canvas.drawLine(Offset(cx - 3, cy - 5), Offset(cx - 7, cy - 1), xp);
    canvas.drawLine(Offset(cx + 3, cy - 5), Offset(cx + 7, cy - 1), xp);
    canvas.drawLine(Offset(cx + 7, cy - 5), Offset(cx + 3, cy - 1), xp);

    // Frown
    final frown = Path()
      ..moveTo(cx - 6, cy + 6)
      ..quadraticBezierTo(cx, cy + 3, cx + 6, cy + 6);
    canvas.drawPath(
      frown,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CriticalIconPainter old) => old.t != t;
}