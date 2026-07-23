import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:flutter/material.dart';

/// Icons drawn with [CustomPaint] so Shorebird patches never depend on
/// MaterialIcons glyphs that are missing from the release tree-shaken font
/// (those missing glyphs often render as Chinese/CJK characters).
class JobsSafeIcon extends StatelessWidget {
  const JobsSafeIcon.insights({super.key, this.size = 20, this.color})
      : _kind = 0;
  const JobsSafeIcon.sparkles({super.key, this.size = 20, this.color})
      : _kind = 1;

  final int _kind;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _JobsSafeIconPainter(
          kind: _kind,
          color: color ?? JobsTheme.primary,
        ),
      ),
    );
  }
}

class _JobsSafeIconPainter extends CustomPainter {
  _JobsSafeIconPainter({required this.kind, required this.color});

  final int kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size.shortestSide;
    final o = Offset((size.width - s) / 2, (size.height - s) / 2);

    switch (kind) {
      case 0: // insights bars
        canvas.drawLine(
          o + Offset(s * 0.22, s * 0.78),
          o + Offset(s * 0.22, s * 0.45),
          paint,
        );
        canvas.drawLine(
          o + Offset(s * 0.5, s * 0.78),
          o + Offset(s * 0.5, s * 0.28),
          paint,
        );
        canvas.drawLine(
          o + Offset(s * 0.78, s * 0.78),
          o + Offset(s * 0.78, s * 0.52),
          paint,
        );
        canvas.drawLine(
          o + Offset(s * 0.15, s * 0.82),
          o + Offset(s * 0.85, s * 0.82),
          paint,
        );
        break;
      case 1: // sparkles
      default:
        canvas.drawLine(
          o + Offset(s * 0.5, s * 0.15),
          o + Offset(s * 0.5, s * 0.85),
          paint,
        );
        canvas.drawLine(
          o + Offset(s * 0.18, s * 0.5),
          o + Offset(s * 0.82, s * 0.5),
          paint,
        );
        canvas.drawLine(
          o + Offset(s * 0.28, s * 0.28),
          o + Offset(s * 0.72, s * 0.72),
          paint,
        );
        canvas.drawLine(
          o + Offset(s * 0.72, s * 0.28),
          o + Offset(s * 0.28, s * 0.72),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _JobsSafeIconPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
