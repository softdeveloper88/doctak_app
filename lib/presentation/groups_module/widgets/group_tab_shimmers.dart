import 'package:doctak_app/presentation/groups_module/widgets/group_nested_tab_scroll.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class _ShimmerPalette {
  final Color base;
  final Color highlight;
  final Color bone;

  const _ShimmerPalette({
    required this.base,
    required this.highlight,
    required this.bone,
  });

  factory _ShimmerPalette.of(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;
    return _ShimmerPalette(
      base: isDark
          ? theme.surfaceVariant.withValues(alpha: 0.3)
          : Colors.grey[300]!,
      highlight: isDark
          ? theme.surfaceVariant.withValues(alpha: 0.5)
          : Colors.grey[100]!,
      bone: isDark
          ? theme.surfaceVariant.withValues(alpha: 0.4)
          : Colors.grey[200]!,
    );
  }
}

class _ShimmerBone extends StatelessWidget {
  final Color color;
  final double? width;
  final double height;
  final double radius;

  const _ShimmerBone({
    required this.color,
    this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

Widget _shimmerWrap(BuildContext context, Widget child) {
  final palette = _ShimmerPalette.of(context);
  return Shimmer.fromColors(
    baseColor: palette.base,
    highlightColor: palette.highlight,
    period: const Duration(milliseconds: 1400),
    child: child,
  );
}

/// Posts tab: compose card + feed post cards.
class GroupFeedTabShimmer extends StatelessWidget {
  final bool showCompose;
  final int itemCount;

  const GroupFeedTabShimmer({
    super.key,
    this.showCompose = true,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final palette = _ShimmerPalette.of(context);

    return _shimmerWrap(
      context,
      Column(
        children: [
          if (showCompose) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.divider),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: palette.bone),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShimmerBone(color: palette.bone, height: 36, radius: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ShimmerBone(color: palette.bone, width: 72, height: 28, radius: 14),
                  const SizedBox(width: 8),
                  _ShimmerBone(color: palette.bone, width: 72, height: 28, radius: 14),
                  const SizedBox(width: 8),
                  _ShimmerBone(color: palette.bone, width: 72, height: 28, radius: 14),
                ],
              ),
            ),
          ],
          ...List.generate(itemCount, (index) => _postCard(context, palette, theme)),
        ],
      ),
    );
  }

  Widget _postCard(BuildContext context, _ShimmerPalette palette, OneUITheme theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: palette.bone),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBone(color: palette.bone, height: 12, width: 140),
                    const SizedBox(height: 6),
                    _ShimmerBone(color: palette.bone, height: 10, width: 90),
                  ],
                ),
              ),
              _ShimmerBone(color: palette.bone, width: 56, height: 20, radius: 10),
            ],
          ),
          const SizedBox(height: 12),
          _ShimmerBone(color: palette.bone, height: 12),
          const SizedBox(height: 6),
          _ShimmerBone(color: palette.bone, height: 12, width: 220),
          const SizedBox(height: 12),
          _ShimmerBone(color: palette.bone, height: 160, radius: 10),
          const SizedBox(height: 12),
          Row(
            children: [
              _ShimmerBone(color: palette.bone, width: 64, height: 10),
              const Spacer(),
              _ShimmerBone(color: palette.bone, width: 48, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// Members tab: avatar row cards with role chip.
class GroupMembersTabShimmer extends StatelessWidget {
  final int itemCount;

  const GroupMembersTabShimmer({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final palette = _ShimmerPalette.of(context);

    return _shimmerWrap(
      context,
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.divider),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: palette.bone),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerBone(color: palette.bone, height: 12, width: 130),
                          const SizedBox(height: 6),
                          _ShimmerBone(color: palette.bone, height: 10, width: 90),
                        ],
                      ),
                    ),
                    _ShimmerBone(color: palette.bone, width: 52, height: 22, radius: 11),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single member row for pagination loading.
class GroupMemberRowShimmer extends StatelessWidget {
  const GroupMemberRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final palette = _ShimmerPalette.of(context);

    return _shimmerWrap(
      context,
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: palette.bone),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBone(color: palette.bone, height: 12, width: 130),
                  const SizedBox(height: 6),
                  _ShimmerBone(color: palette.bone, height: 10, width: 90),
                ],
              ),
            ),
            _ShimmerBone(color: palette.bone, width: 52, height: 22, radius: 11),
          ],
        ),
      ),
    );
  }
}

/// Polls tab: poll cards with option rows.
class GroupPollsTabShimmer extends StatelessWidget {
  final int itemCount;

  const GroupPollsTabShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final palette = _ShimmerPalette.of(context);

    return _shimmerWrap(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        child: Column(
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBone(color: palette.bone, height: 12, width: 48),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(radius: 14, backgroundColor: palette.bone),
                        const SizedBox(width: 8),
                        _ShimmerBone(color: palette.bone, height: 10, width: 100),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ShimmerBone(color: palette.bone, height: 14, width: 200),
                    const SizedBox(height: 6),
                    _ShimmerBone(color: palette.bone, height: 10),
                    const SizedBox(height: 12),
                    ...List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ShimmerBone(color: palette.bone, height: 40, radius: 10),
                      ),
                    ),
                    _ShimmerBone(color: palette.bone, height: 10, width: 70),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Media tab: 3-column image grid.
class GroupMediaTabShimmer extends StatelessWidget {
  final int itemCount;

  const GroupMediaTabShimmer({super.key, this.itemCount = 12});

  @override
  Widget build(BuildContext context) {
    final palette = _ShimmerPalette.of(context);

    return _shimmerWrap(
      context,
      Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: itemCount,
          itemBuilder: (_, __) => _ShimmerBone(
            color: palette.bone,
            height: double.infinity,
            radius: 8,
          ),
        ),
      ),
    );
  }
}

/// Single media grid tile placeholder.
class GroupMediaTileShimmer extends StatelessWidget {
  const GroupMediaTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = _ShimmerPalette.of(context);
    return _shimmerWrap(
      context,
      _ShimmerBone(color: palette.bone, height: double.infinity, radius: 8),
    );
  }
}

/// Analytics section placeholder (single card + 2x2 grid).
class GroupAnalyticsSectionShimmer extends StatelessWidget {
  const GroupAnalyticsSectionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final palette = _ShimmerPalette.of(context);

    return _shimmerWrap(
      context,
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBone(color: palette.bone, height: 14, width: 90),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: List.generate(
                4,
                (_) => _ShimmerBone(color: palette.bone, height: double.infinity, radius: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Moderation queue placeholder cards.
class GroupModerationSectionShimmer extends StatelessWidget {
  final int itemCount;

  const GroupModerationSectionShimmer({super.key, this.itemCount = 2});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final palette = _ShimmerPalette.of(context);

    return _shimmerWrap(
      context,
      Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBone(color: palette.bone, height: 12),
                  const SizedBox(height: 6),
                  _ShimmerBone(color: palette.bone, height: 12, width: 200),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ShimmerBone(color: palette.bone, height: 36, radius: 8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ShimmerBone(color: palette.bone, height: 36, radius: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// About tab: section cards + analytics grid.
class GroupInfoTabShimmer extends StatelessWidget {
  final bool showModeration;

  const GroupInfoTabShimmer({super.key, this.showModeration = false});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final palette = _ShimmerPalette.of(context);

    return _shimmerWrap(
      context,
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionCard(theme, palette, lines: 2, chips: 2),
            const SizedBox(height: 16),
            _sectionCard(theme, palette, titleWidth: 90, showGrid: true),
            const SizedBox(height: 16),
            _sectionCard(theme, palette, lines: 4),
            if (showModeration) ...[
              const SizedBox(height: 16),
              _ShimmerBone(color: palette.bone, height: 16, width: 72),
              const SizedBox(height: 10),
              _moderationCard(theme, palette),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    OneUITheme theme,
    _ShimmerPalette palette, {
    double titleWidth = 70,
    int lines = 0,
    int chips = 0,
    bool showGrid = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBone(color: palette.bone, height: 14, width: titleWidth),
          if (lines > 0) ...[
            const SizedBox(height: 10),
            ...List.generate(
              lines,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ShimmerBone(
                  color: palette.bone,
                  height: 10,
                  width: i == lines - 1 ? 180 : double.infinity,
                ),
              ),
            ),
          ],
          if (chips > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                chips,
                (i) => Padding(
                  padding: EdgeInsets.only(right: i == chips - 1 ? 0 : 6),
                  child: _ShimmerBone(
                    color: palette.bone,
                    width: i == 0 ? 64 : 120,
                    height: 22,
                    radius: 11,
                  ),
                ),
              ),
            ),
          ],
          if (showGrid) ...[
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: List.generate(
                4,
                (_) => _ShimmerBone(color: palette.bone, height: double.infinity, radius: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _moderationCard(OneUITheme theme, _ShimmerPalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBone(color: palette.bone, height: 12),
          const SizedBox(height: 6),
          _ShimmerBone(color: palette.bone, height: 12, width: 200),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ShimmerBone(color: palette.bone, height: 36, radius: 8)),
              const SizedBox(width: 8),
              Expanded(child: _ShimmerBone(color: palette.bone, height: 36, radius: 8)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wraps a tab shimmer for [NestedScrollView] tab bodies.
class GroupTabShimmerScroll extends StatelessWidget {
  final Widget shimmer;

  const GroupTabShimmerScroll({super.key, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return GroupNestedTabScroll(
      slivers: [
        SliverToBoxAdapter(child: shimmer),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
