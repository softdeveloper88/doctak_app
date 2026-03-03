import 'package:doctak_app/presentation/guideline_module/data/models/guideline_chat_model.dart';
import 'package:flutter/material.dart';

/// Quota/usage banner for guideline AI — shows remaining queries.
/// Matches the upgrade prompt from the reference design.
class GuidelineQuotaBanner extends StatelessWidget {
  final GuidelineUsageInfo usage;
  final VoidCallback onUpgrade;

  const GuidelineQuotaBanner({
    super.key,
    required this.usage,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    // Hide for paid users or unlimited
    if (usage.isPaid || usage.dailyLimit == -1) {
      return const SizedBox.shrink();
    }

    final isExhausted = !usage.canUse || usage.dailyRemaining <= 0;
    final isLow = usage.dailyRemaining <= 2 && !isExhausted;

    // Choose colors based on severity
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Color progressColor;
    final IconData icon;

    if (isExhausted) {
      bgColor = const Color(0xFFFF3B30).withOpacity(0.06);
      borderColor = const Color(0xFFFF3B30);
      textColor = const Color(0xFFFF3B30);
      progressColor = const Color(0xFFFF3B30);
      icon = Icons.block_rounded;
    } else if (isLow) {
      bgColor = const Color(0xFFFF9500).withOpacity(0.06);
      borderColor = const Color(0xFFFF9500);
      textColor = const Color(0xFFFF9500);
      progressColor = const Color(0xFFFF9500);
      icon = Icons.warning_amber_rounded;
    } else {
      bgColor = const Color(0xFF0A84FF).withOpacity(0.04);
      borderColor = const Color(0xFF0A84FF);
      textColor = const Color(0xFF0A84FF);
      progressColor = const Color(0xFF0A84FF);
      icon = Icons.auto_awesome_outlined;
    }

    final message = isExhausted
        ? 'Free limit reached. Upgrade for unlimited.'
        : 'Queries: ${usage.dailyRemaining}/${usage.dailyLimit}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor.withOpacity(0.3), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Upgrade pill button
              Material(
                color: borderColor,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onUpgrade,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 12, color: Colors.white),
                        SizedBox(width: 3),
                        Text(
                          'Upgrade',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: usage.dailyLimit > 0
                  ? usage.dailyUsed / usage.dailyLimit
                  : 0,
              backgroundColor: progressColor.withOpacity(0.12),
              color: progressColor,
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
