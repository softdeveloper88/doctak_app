import 'package:flutter/material.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';

class CmeCreditBadge extends StatelessWidget {
  final String creditType;
  final dynamic creditAmount;
  final bool compact;

  const CmeCreditBadge({
    super.key,
    required this.creditType,
    required this.creditAmount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    if (creditAmount == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _getBadgeColor(creditType, theme).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: Border.all(
          color: _getBadgeColor(creditType, theme).withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: compact ? 12 : 14,
            color: _getBadgeColor(creditType, theme),
          ),
          SizedBox(width: compact ? 3 : 5),
          Text(
            '$creditAmount ${creditType.toUpperCase()}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: _getBadgeColor(creditType, theme),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String type, OneUITheme theme) {
    switch (type.toLowerCase()) {
      case 'ama pra category 1':
      case 'category_1':
        return theme.primary;
      case 'ama pra category 2':
      case 'category_2':
        return const Color(0xFF6366F1);
      case 'moc':
        return theme.warning;
      case 'ce':
        return theme.success;
      default:
        return theme.primary;
    }
  }
}
