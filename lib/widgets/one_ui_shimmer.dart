import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Theme-aware shimmer wrapper — uses [OneUITheme.shimmerBase] and
/// [OneUITheme.shimmerHighlight] so loading states match light/dark mode.
class OneUIShimmer extends StatelessWidget {
  final Widget child;
  final Duration? period;

  const OneUIShimmer({
    super.key,
    required this.child,
    this.period,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.shimmerBase,
      highlightColor: theme.shimmerHighlight,
      period: period ?? const Duration(milliseconds: 1300),
      child: child,
    );
  }
}
