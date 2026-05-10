// ── Normal card ──────────────────────────────────────────
import 'package:flutter/material.dart';
import 'status_card.dart';
import 'theme_colors.dart';

class NormalCard extends StatefulWidget {
  final VoidCallback? onViewHistory;
  const NormalCard({super.key, this.onViewHistory});

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
    _bob = Tween(begin: 0.0, end: -4.0).animate(
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
      animation: _bob,
      builder: (_, _) => StatusCard(
        color: StatusColors.normalPrimary,
        bgColor: StatusColors.normalBg,
        darkColor: StatusColors.normalDark,
        badge: 'All clear',
        title: 'Everything looks good',
        subtitle: 'No anomalies detected. All vitals within normal parameters.',
        actionLabel: 'View history',
        onAction: widget.onViewHistory,
        icon: Transform.translate(
          offset: Offset(0, _bob.value),
          child: CustomPaint(
            size: const Size(32, 32),
            painter: _NormalIconPainter(),
          ),
        ),
      ),
    );
  }
}

class _NormalIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;

    canvas.drawCircle(Offset(cx, cy), 13, Paint()..color = StatusColors.normalBg);
    canvas.drawCircle(
      Offset(cx, cy),
      13,
      Paint()
        ..color = StatusColors.normalAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Eyes
    canvas.drawCircle(
      Offset(cx - 4, cy - 3), 2, Paint()..color = StatusColors.normalDark);
    canvas.drawCircle(
      Offset(cx + 4, cy - 3), 2, Paint()..color = StatusColors.normalDark);

    // Smile
    final smile = Path()
      ..moveTo(cx - 6, cy + 3)
      ..quadraticBezierTo(cx, cy + 8, cx + 6, cy + 3);
    canvas.drawPath(
      smile,
      Paint()
        ..color = StatusColors.normalDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}