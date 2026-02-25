import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'package:doctak_app/presentation/subscription_screen/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// A reusable quota banner used across all AI screens.
///
/// **Always visible** for free-plan users so they can see their
/// remaining messages and upgrade at any time.
///
/// States:
/// - **Info** (blue): plenty of quota remaining – shows count + "Upgrade" link.
/// - **Warning** (amber): ≤ 3 messages remaining.
/// - **Exhausted** (red): no messages left, hard block + "Upgrade" button.
/// - **Hidden** for paid / unlimited users.
///
/// Usage:
/// ```dart
/// AiQuotaBanner(usage: state.quotaInfo)
/// ```
class AiQuotaBanner extends StatelessWidget {
  final AiUsageInfo? usage;

  const AiQuotaBanner({super.key, this.usage});

  @override
  Widget build(BuildContext context) {
    if (usage == null) return const SizedBox.shrink();

    // Paid / unlimited — no banner needed
    if (usage!.isPaid || usage!.dailyLimit == -1) return const SizedBox.shrink();

    final bool exhausted = !usage!.canUse || usage!.dailyRemaining <= 0;
    final bool lowWarning = !exhausted && usage!.dailyRemaining <= 3;

    // ── Pick colours & icon based on severity ──────────────────────────
    late final Color bg;
    late final Color border;
    late final Color fg;
    late final IconData icon;
    late final Color upgradeBg;

    if (exhausted) {
      bg       = const Color(0xFFFFEBEE);
      border   = const Color(0xFFEF9A9A);
      fg       = const Color(0xFFC62828);
      icon     = Icons.block_rounded;
      upgradeBg = const Color(0xFFC62828);
    } else if (lowWarning) {
      bg       = const Color(0xFFFFF8E1);
      border   = const Color(0xFFFFCC02);
      fg       = const Color(0xFFE65100);
      icon     = Icons.warning_amber_rounded;
      upgradeBg = const Color(0xFFE65100);
    } else {
      // Plenty remaining — subtle info style
      bg       = const Color(0xFFE8F0FE);
      border   = const Color(0xFF90CAF9);
      fg       = const Color(0xFF1565C0);
      icon     = Icons.auto_awesome_outlined;
      upgradeBg = const Color(0xFF1565C0);
    }

    // ── Message text ──────────────────────────────────────────────────
    final String message = exhausted
        ? 'Free limit reached (${usage!.dailyUsed}/${usage!.dailyLimit} used). Upgrade for unlimited.'
        : '${usage!.dailyRemaining}/${usage!.dailyLimit} free messages left';

    // ── Progress fraction (used for the thin bar) ─────────────────────
    final double progress = usage!.dailyLimit > 0
        ? (usage!.dailyUsed / usage!.dailyLimit).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: fg, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => const SubscriptionScreen().launch(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: upgradeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond_outlined, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text(
                        'Upgrade',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Thin usage progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(fg),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
