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
              // Banner shimmer
              _ShimmerBox(
                width: double.infinity,
                height: 140,
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ShimmerBox(width: 60, height: 20, isDark: isDark),
                        const SizedBox(width: 8),
                        _ShimmerBox(width: 80, height: 20, isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ShimmerBox(width: double.infinity, height: 18, isDark: isDark),
                    const SizedBox(height: 6),
                    _ShimmerBox(width: 200, height: 14, isDark: isDark),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ShimmerBox(width: 120, height: 14, isDark: isDark),
                        const SizedBox(width: 12),
                        _ShimmerBox(width: 100, height: 14, isDark: isDark),
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

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final bool isDark;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.isDark,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
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
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: widget.isDark
                  ? [
                      const Color(0xFF2D3E50),
                      const Color(0xFF374F65),
                      const Color(0xFF2D3E50),
                    ]
                  : [
                      const Color(0xFFE8E8E8),
                      const Color(0xFFF5F5F5),
                      const Color(0xFFE8E8E8),
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
