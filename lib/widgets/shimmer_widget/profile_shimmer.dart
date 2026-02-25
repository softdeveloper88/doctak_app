import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading placeholder that mirrors the actual
/// [SVProfileHeaderComponent] layout (OneUI 8.5 style).
class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;

    final baseColor = isDark
        ? theme.surfaceVariant.withValues(alpha: 0.3)
        : Colors.grey[300]!;
    final highlightColor = isDark
        ? theme.surfaceVariant.withValues(alpha: 0.5)
        : Colors.grey[100]!;
    final bone = isDark
        ? theme.surfaceVariant.withValues(alpha: 0.4)
        : Colors.grey[200]!;
    final cardBg = theme.cardBackground;
    final borderColor = theme.border;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════
            //  COVER + AVATAR (matches header Stack)
            // ═══════════════════════════════════════
            SizedBox(
              // 200px cover + 60px overflow for avatar/buttons
              height: 260,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Cover image placeholder ──
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(height: 200, color: bone),
                  ),

                  // ── Back button circle ──
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // ── Avatar (left-aligned, overlapping cover) ──
                  PositionedDirectional(
                    top: 200 - 56, // half of 112px avatar hangs over cover
                    start: 20,
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bone,
                        border: Border.all(color: cardBg, width: 4),
                      ),
                    ),
                  ),

                  // ── Action buttons placeholder (right side) ──
                  PositionedDirectional(
                    top: 200 + 8,
                    end: 20,
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 36,
                          decoration: BoxDecoration(
                            color: bone,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 80,
                          height: 36,
                          decoration: BoxDecoration(
                            color: bone,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════
            //  NAME + POINTS BADGE
            // ═══════════════════════════════════════
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 8),
              child: Row(
                children: [
                  // Name bone
                  Container(
                    width: 160,
                    height: 20,
                    decoration: BoxDecoration(
                      color: bone,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Points badge bone
                  Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: bone,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════
            //  SPECIALTY + LOCATION ROW
            // ═══════════════════════════════════════
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 6),
              child: Row(
                children: [
                  // Specialty icon
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: bone,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: bone,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dot separator
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: bone,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Location
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: bone,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════
            //  STATS CARD (Posts / Connections / Followers)
            // ═══════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    _buildStatBone(bone),
                    _buildStatBone(bone),
                    _buildStatBone(bone),
                  ],
                ),
              ),
            ),

            // ═══════════════════════════════════════
            //  TAB BAR PLACEHOLDER
            // ═══════════════════════════════════════
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: List.generate(
                  4,
                  (_) => Expanded(
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 12,
                        decoration: BoxDecoration(
                          color: bone,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ═══════════════════════════════════════
            //  SECTION CARD PLACEHOLDERS
            // ═══════════════════════════════════════
            for (int i = 0; i < 2; i++) ...[
              _buildSectionCardBone(bone, cardBg, borderColor),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// A single stat column matching [StatItem] layout.
  Widget _buildStatBone(Color bone) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 18,
            decoration: BoxDecoration(
              color: bone,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 55,
            height: 10,
            decoration: BoxDecoration(
              color: bone,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// A card placeholder for About / Contact / Professional sections.
  Widget _buildSectionCardBone(
      Color bone, Color cardBg, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title bone
          Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: bone,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // Row bones
          for (int i = 0; i < 3; i++) ...[
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: bone,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 80 + (i * 20),
                  height: 14,
                  decoration: BoxDecoration(
                    color: bone,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            if (i < 2) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
