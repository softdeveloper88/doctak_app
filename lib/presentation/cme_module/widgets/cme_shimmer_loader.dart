import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

class CmeShimmerLoader extends StatelessWidget {
  final int itemCount;

  const CmeShimmerLoader({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: theme.cardDecoration,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CmeShimmerBox(width: double.infinity, height: 140, isDark: isDark),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CmeShimmerBox(width: 60, height: 20, isDark: isDark),
                        const SizedBox(width: 8),
                        CmeShimmerBox(width: 80, height: 20, isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CmeShimmerBox(width: double.infinity, height: 18, isDark: isDark),
                    const SizedBox(height: 6),
                    CmeShimmerBox(width: 200, height: 14, isDark: isDark),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CmeShimmerBox(width: 120, height: 14, isDark: isDark),
                        const SizedBox(width: 12),
                        CmeShimmerBox(width: 100, height: 14, isDark: isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-screen shimmer for CME event detail loading.
class CmeEventDetailShimmer extends StatelessWidget {
  const CmeEventDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: CmeShimmerBox(width: double.infinity, height: 220, isDark: isDark),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CmeShimmerBox(width: 72, height: 22, isDark: isDark, radius: 12),
                    const SizedBox(width: 8),
                    CmeShimmerBox(width: 56, height: 22, isDark: isDark, radius: 12),
                  ],
                ),
                const SizedBox(height: 14),
                CmeShimmerBox(width: double.infinity, height: 24, isDark: isDark),
                const SizedBox(height: 8),
                CmeShimmerBox(width: 160, height: 16, isDark: isDark),
                const SizedBox(height: 16),
                CmeShimmerBox(width: double.infinity, height: 48, isDark: isDark, radius: 10),
                const SizedBox(height: 16),
                _progressCardShimmer(isDark),
                const SizedBox(height: 16),
                _detailsCardShimmer(theme, isDark),
                const SizedBox(height: 16),
                CmeShimmerBox(width: double.infinity, height: 40, isDark: isDark, radius: 8),
                const SizedBox(height: 12),
                _tabPanelShimmer(theme, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressCardShimmer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A36) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2D3E50) : const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CmeShimmerBox(width: 100, height: 14, isDark: isDark),
              const Spacer(),
              CmeShimmerBox(width: 36, height: 14, isDark: isDark),
            ],
          ),
          const SizedBox(height: 12),
          CmeShimmerBox(width: double.infinity, height: 6, isDark: isDark, radius: 4),
          const SizedBox(height: 18),
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Column(
                  children: [
                    CmeShimmerBox(width: 24, height: 24, isDark: isDark, radius: 12),
                    const SizedBox(height: 8),
                    CmeShimmerBox(width: 48, height: 10, isDark: isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCardShimmer(OneUITheme theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                CmeShimmerBox(width: 18, height: 18, isDark: isDark, radius: 4),
                const SizedBox(width: 12),
                CmeShimmerBox(width: 70, height: 12, isDark: isDark),
                const SizedBox(width: 12),
                Expanded(child: CmeShimmerBox(width: double.infinity, height: 12, isDark: isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabPanelShimmer(OneUITheme theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CmeShimmerBox(width: 120, height: 14, isDark: isDark),
          const SizedBox(height: 10),
          CmeShimmerBox(width: double.infinity, height: 12, isDark: isDark),
          const SizedBox(height: 6),
          CmeShimmerBox(width: double.infinity, height: 12, isDark: isDark),
          const SizedBox(height: 6),
          CmeShimmerBox(width: 220, height: 12, isDark: isDark),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for tab panel content (agenda / speakers).
class CmeTabPanelShimmer extends StatelessWidget {
  const CmeTabPanelShimmer({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: List.generate(
        rows,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CmeShimmerBox(width: 28, height: 28, isDark: isDark, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CmeShimmerBox(width: double.infinity, height: 14, isDark: isDark),
                    const SizedBox(height: 6),
                    CmeShimmerBox(width: 180, height: 11, isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CmeShimmerBox extends StatefulWidget {
  const CmeShimmerBox({
    super.key,
    required this.width,
    required this.height,
    required this.isDark,
    this.radius = 6,
  });

  final double width;
  final double height;
  final bool isDark;
  final double radius;

  @override
  State<CmeShimmerBox> createState() => _CmeShimmerBoxState();
}

class _CmeShimmerBoxState extends State<CmeShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      listenable: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: widget.isDark
                  ? const [
                      Color(0xFF2D3E50),
                      Color(0xFF374F65),
                      Color(0xFF2D3E50),
                    ]
                  : const [
                      Color(0xFFE8E8E8),
                      Color(0xFFF5F5F5),
                      Color(0xFFE8E8E8),
                    ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, null);
}
