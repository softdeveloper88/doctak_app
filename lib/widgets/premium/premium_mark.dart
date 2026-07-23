import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:flutter/material.dart';

/// Shared premium gold tokens (parity with web `.dt-premium-mark` / avatar ring).
abstract final class PremiumStyle {
  static const Color gold = Color(0xFFE6B422);
  static const Color goldDeep = Color(0xFF8A6508);
  static const Color goldLight = Color(0xFFFFE9A0);
  static const Color verifiedBlue = Color(0xFF1DA1F2);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDeep],
  );

  /// DocTak brand mark used for premium labels.
  static const String logoAsset = 'assets/logo/logo.png';
}

const _premiumBenefits = <String>[
  'Stand out with a gold DocTak Premium badge',
  'Unlock higher AI diagnosis and guideline limits',
  'Get priority visibility across DocTak',
  'Access Professional tools for your practice',
];

/// LinkedIn-style Premium upsell sheet — CTA opens [SubscriptionScreen].
Future<void> showPremiumUpgradeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.fromLTRB(22, 12, 22, 16 + bottom),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            const PremiumMark(size: 48),
            const SizedBox(height: 16),
            Text(
              'Unlock DocTak Premium',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This member is on Premium. Upgrade to get the same badge, tools, and visibility across DocTak.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            ..._premiumBenefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: PremiumStyle.goldGradient,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        benefit,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: PremiumStyle.goldGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      AppNavigator.toSubscription(context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Upgrade now',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF5C4408),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(
                'Not now',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Gold square with white DocTak logo — replaces "Premium" text pills.
class PremiumMark extends StatelessWidget {
  const PremiumMark({
    super.key,
    this.size = 16,
    this.title = 'Premium member',
    this.openUpgradeOnTap = false,
  });

  final double size;
  final String title;

  /// When true (other users' badges), tap opens the Premium upsell sheet
  /// if the viewer is not already Premium.
  final bool openUpgradeOnTap;

  @override
  Widget build(BuildContext context) {
    final logoSize = size * 0.82;

    final mark = Semantics(
      label: title,
      button: openUpgradeOnTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: PremiumStyle.goldGradient,
          boxShadow: [
            BoxShadow(
              color: PremiumStyle.goldDeep.withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Image.asset(
          PremiumStyle.logoAsset,
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          filterQuality: FilterQuality.high,
        ),
      ),
    );

    if (!openUpgradeOnTap) return mark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (AppData.isPremium) return;
        showPremiumUpgradeSheet(context);
      },
      child: mark,
    );
  }
}

/// Verified check — gold when [isPremium], otherwise DocTak blue.
class DocTakVerifiedBadge extends StatelessWidget {
  const DocTakVerifiedBadge({
    super.key,
    this.size = 16,
    this.isPremium = false,
  });

  final double size;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified_rounded,
      size: size,
      color: isPremium ? PremiumStyle.gold : PremiumStyle.verifiedBlue,
    );
  }
}

/// Wraps an avatar with a gold ring when [isPremium] is true.
class PremiumAvatarRing extends StatelessWidget {
  const PremiumAvatarRing({
    super.key,
    required this.child,
    this.isPremium = false,
    this.size,
    this.ringWidth = 2.5,
  });

  final Widget child;
  final bool isPremium;
  final double? size;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    if (!isPremium) return child;

    final wrapped = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: PremiumStyle.gold.withValues(alpha: 0.55),
            blurRadius: 0,
            spreadRadius: ringWidth + 1.5,
          ),
          BoxShadow(
            color: PremiumStyle.gold,
            blurRadius: 0,
            spreadRadius: ringWidth,
          ),
        ],
      ),
      child: ClipOval(child: child),
    );

    return Tooltip(message: 'Premium member', child: wrapped);
  }
}
