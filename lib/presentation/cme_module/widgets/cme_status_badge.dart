import 'package:flutter/material.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';

class CmeStatusBadge extends StatelessWidget {
  final String status;
  final bool onDark;

  const CmeStatusBadge({
    super.key,
    required this.status,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final config = _getConfig(status, theme);

    final bgColor = onDark
        ? Colors.white.withValues(alpha: 0.94)
        : config.color.withValues(alpha: 0.12);
    final textColor = onDark ? config.onDarkColor : config.color;
    final dotColor = onDark ? config.onDarkColor : config.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: onDark ? Border.all(color: Colors.white.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getConfig(String status, OneUITheme theme) {
    switch (status.toLowerCase()) {
      case 'live':
      case 'in_progress':
        return _StatusConfig('LIVE', theme.error, theme.error);
      case 'upcoming':
      case 'published':
        return _StatusConfig('UPCOMING', theme.primary, theme.primary);
      case 'completed':
      case 'ended':
        return _StatusConfig('ENDED', const Color(0xFF374151), const Color(0xFF374151));
      case 'credit_earned':
        return _StatusConfig('CREDIT EARNED', theme.success, const Color(0xFF166534));
      case 'credit_pending':
      case 'credit in progress':
        return _StatusConfig('IN PROGRESS', theme.warning, const Color(0xFFB45309));
      case 'cancelled':
        return _StatusConfig('CANCELLED', const Color(0xFF8E8E93), const Color(0xFF6B7280));
      case 'draft':
        return _StatusConfig('DRAFT', theme.warning, const Color(0xFFB45309));
      default:
        return _StatusConfig(status.toUpperCase(), const Color(0xFF8E8E93), const Color(0xFF6B7280));
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final Color onDarkColor;
  _StatusConfig(this.label, this.color, this.onDarkColor);
}
