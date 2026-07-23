import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Motion tokens for home feed — short, purposeful, respects reduced motion.
abstract final class FeedMotion {
  static const Duration feedback = Duration(milliseconds: 120);
  static const Duration entrance = Duration(milliseconds: 220);
  static const Duration staggerStep = Duration(milliseconds: 50);
  static const int maxStaggeredItems = 10;
  static const double entranceOffset = 10;
  static const double pressScale = 0.94;
  static const Curve curve = Curves.easeOutCubic;

  static bool enabled(BuildContext context) =>
      !MediaQuery.disableAnimationsOf(context);
}

/// Staggered fade + slide for the first visible feed cards after load.
class FeedCardEntrance extends StatelessWidget {
  final int listIndex;
  final Widget child;

  const FeedCardEntrance({
    super.key,
    required this.listIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!FeedMotion.enabled(context) ||
        listIndex >= FeedMotion.maxStaggeredItems) {
      return child;
    }

    return AnimationConfiguration.staggeredList(
      position: listIndex,
      duration: FeedMotion.entrance,
      delay: FeedMotion.staggerStep,
      child: SlideAnimation(
        verticalOffset: FeedMotion.entranceOffset,
        curve: FeedMotion.curve,
        child: FadeInAnimation(
          curve: FeedMotion.curve,
          child: child,
        ),
      ),
    );
  }
}

/// Quick scale-down on press for feed action targets.
class FeedPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;

  const FeedPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<FeedPressScale> createState() => _FeedPressScaleState();
}

class _FeedPressScaleState extends State<FeedPressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final motion = FeedMotion.enabled(context);
    final scale = motion && _pressed ? FeedMotion.pressScale : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: FeedMotion.feedback,
      curve: FeedMotion.curve,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onHighlightChanged: motion
            ? (highlighted) {
                if (_pressed != highlighted) {
                  setState(() => _pressed = highlighted);
                }
              }
            : null,
        borderRadius: widget.borderRadius,
        child: widget.child,
      ),
    );
  }
}
