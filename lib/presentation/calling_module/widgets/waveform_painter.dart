// lib/presentation/call_module/widgets/waveform_painter.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// CustomPainter that draws audio waveform pattern
class AudioWaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();

    // Create a simple audio waveform pattern
    final double width = size.width;
    final double height = size.height;
    final double centerY = height / 2;

    // Draw horizontal wave patterns
    for (int i = 0; i < 10; i++) {
      double offsetY = centerY + (i - 5) * 80;

      path.moveTo(0, offsetY);

      for (double x = 0; x < width; x += 10) {
        path.lineTo(x, offsetY + 20 * math.sin(x / 50));
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
