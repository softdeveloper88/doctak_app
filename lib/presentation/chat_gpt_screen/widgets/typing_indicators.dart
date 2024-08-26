import 'package:flutter/material.dart';

class TypingIndicators extends StatefulWidget {
  final Color color;
  final double size;

  const TypingIndicators({super.key, required this.color, this.size = 10.0});

  @override
  TypingIndicatorState createState() => TypingIndicatorState();
}

class TypingIndicatorState extends State<TypingIndicators>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      )
        ..repeat();
    });

    _animations = _controllers
        .asMap()
        .map((i, controller) {
      return MapEntry(
        i,
        Tween(begin: 0.0, end: 8.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(0.2 * i, 1.0, curve: Curves.easeInOut),
          ),
        ),
      );
    })
        .values
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_animations[index].value),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: CircleAvatar(
              radius: widget.size,
              backgroundColor: widget.color,
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
