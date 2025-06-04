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
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      )..repeat(reverse: true);
    });

    _animations = _controllers
        .asMap()
        .map((i, controller) {
          return MapEntry(
            i,
            Tween(begin: 0.0, end: 10.0).animate(
              CurvedAnimation(
                parent: controller,
                curve: Interval(0.2 * i, 0.6 + 0.1 * i, curve: Curves.easeOutCubic),
              ),
            ),
          );
        })
        .values
        .toList();

    _opacityAnimations = _controllers
        .asMap()
        .map((i, controller) {
          return MapEntry(
            i,
            Tween(begin: 0.4, end: 1.0).animate(
              CurvedAnimation(
                parent: controller,
                curve: Interval(0.1 * i, 0.5 + 0.2 * i, curve: Curves.easeInOut),
              ),
            ),
          );
        })
        .values
        .toList();
        
    // Start controllers with slight delay to create wave effect
    Future.delayed(Duration(milliseconds: 100), () {
      _controllers[0].forward();
    });
    
    Future.delayed(Duration(milliseconds: 200), () {
      _controllers[1].forward();
    });
    
    Future.delayed(Duration(milliseconds: 300), () {
      _controllers[2].forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_animations[index].value),
                child: Opacity(
                  opacity: _opacityAnimations[index].value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: Container(
                width: widget.size * 2,
                height: widget.size * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color == Colors.white
                          ? Colors.white
                          : Colors.blue[400]!,
                      widget.color == Colors.white
                          ? Colors.white.withOpacity(0.9)
                          : Colors.blue[600]!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color == Colors.white
                          ? Colors.white.withOpacity(0.5)
                          : Colors.blue.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
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
