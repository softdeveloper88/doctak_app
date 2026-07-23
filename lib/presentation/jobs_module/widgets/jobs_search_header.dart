import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

class JobSectionLabel extends StatelessWidget {
  const JobSectionLabel(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: JobsTheme.eyebrow.copyWith(color: color ?? JobsTheme.onSurfaceVariant),
    );
  }
}

class JobLogoAvatar extends StatelessWidget {
  const JobLogoAvatar({
    super.key,
    this.imageUrl,
    this.size = 48,
    this.radius = 12,
  });

  final String? imageUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = _JobLogoPlaceholder(size: size, radius: radius);

    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AppCachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: (size * 3).round(),
        memCacheHeight: (size * 3).round(),
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }
}

/// Fontless company placeholder — avoids MaterialIcons PUA → CJK glyph bugs.
class _JobLogoPlaceholder extends StatelessWidget {
  const _JobLogoPlaceholder({required this.size, required this.radius});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: JobsTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.46,
          height: size * 0.46,
          child: CustomPaint(
            painter: _BuildingPlaceholderPainter(color: JobsTheme.primary),
          ),
        ),
      ),
    );
  }
}

class _BuildingPlaceholderPainter extends CustomPainter {
  _BuildingPlaceholderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.15, h * 0.9)
      ..lineTo(w * 0.15, h * 0.35)
      ..lineTo(w * 0.5, h * 0.12)
      ..lineTo(w * 0.85, h * 0.35)
      ..lineTo(w * 0.85, h * 0.9)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.55), Offset(w * 0.5, h * 0.9), paint);
    canvas.drawLine(Offset(w * 0.32, h * 0.5), Offset(w * 0.32, h * 0.62), paint);
    canvas.drawLine(Offset(w * 0.68, h * 0.5), Offset(w * 0.68, h * 0.62), paint);
  }

  @override
  bool shouldRepaint(covariant _BuildingPlaceholderPainter oldDelegate) =>
      oldDelegate.color != color;
}
