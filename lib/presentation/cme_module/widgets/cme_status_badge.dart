import 'package:flutter/material.dart';

class CmeStatusBadge extends StatelessWidget {
  final String status;

  const CmeStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.color,
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
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getConfig(String status) {
    switch (status.toLowerCase()) {
      case 'live':
      case 'in_progress':
        return _StatusConfig('LIVE', const Color(0xFFFF3B30));
      case 'upcoming':
      case 'published':
        return _StatusConfig('UPCOMING', const Color(0xFF0A84FF));
      case 'completed':
      case 'ended':
        return _StatusConfig('COMPLETED', const Color(0xFF34C759));
      case 'cancelled':
        return _StatusConfig('CANCELLED', const Color(0xFF8E8E93));
      case 'draft':
        return _StatusConfig('DRAFT', const Color(0xFFFF9500));
      default:
        return _StatusConfig(status.toUpperCase(), const Color(0xFF8E8E93));
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  _StatusConfig(this.label, this.color);
}
