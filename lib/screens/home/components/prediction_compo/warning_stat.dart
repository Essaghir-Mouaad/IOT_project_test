// ── Warning card ─────────────────────────────────────────
import 'package:flutter/material.dart';
import 'status_card.dart';
import 'theme_colors.dart';

class WarningCard extends StatefulWidget {
  final VoidCallback? onReview;
  const WarningCard({super.key, this.onReview});

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
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _swing = Tween(begin: -0.18, end: 0.18).animate(
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
      animation: _swing,
      builder: (_, __) => StatusCard(
        color: StatusColors.warningPrimary,
        bgColor: StatusColors.warningBg,
        darkColor: StatusColors.warningDark,
        badge: 'Warning',
        title: 'Unusual pattern detected',
        subtitle: 'Vitals outside expected range. Clinical review is recommended soon.',
        actionLabel: 'Review readings',
        onAction: widget.onReview,
        icon: CustomPaint(
          size: const Size(32, 32),
          painter: _WarningIconPainter(_swing.value),
        ),
      ),
    );
  }
}

class _WarningIconPainter extends CustomPainter {
  final double angle;
  _WarningIconPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2 + 2;
    final amber = StatusColors.warningAccent;
    final dark = StatusColors.warningDark;

    canvas.drawCircle(Offset(cx, cy), 12, Paint()..color = StatusColors.warningBg);
    canvas.drawCircle(
      Offset(cx, cy),
      12,
      Paint()
        ..color = amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Eyes
    canvas.drawCircle(Offset(cx - 4.5, cy - 3), 2, Paint()..color = dark);
    canvas.drawCircle(Offset(cx + 4.5, cy - 3), 2, Paint()..color = dark);

    // Frown
    final frown = Path()
      ..moveTo(cx - 5, cy + 5)
      ..quadraticBezierTo(cx, cy + 2, cx + 5, cy + 5);
    canvas.drawPath(
      frown,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    // Swinging hands above head
    canvas.save();
    canvas.translate(cx, cy - 14);
    canvas.rotate(angle);
    final hp = Paint()
      ..color = amber
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-9, 0), const Offset(0, 5), hp);
    canvas.drawLine(const Offset(9, 0), const Offset(0, 5), hp);
    canvas.drawCircle(
      const Offset(-10, 0),
      3,
      Paint()
        ..color = StatusColors.warningBg
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      const Offset(-10, 0),
      3,
      Paint()
        ..color = amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      const Offset(10, 0),
      3,
      Paint()
        ..color = StatusColors.warningBg
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      const Offset(10, 0),
      3,
      Paint()
        ..color = amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WarningIconPainter old) => old.angle != angle;
}