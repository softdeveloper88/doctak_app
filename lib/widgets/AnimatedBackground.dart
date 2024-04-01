import 'dart:async';
import 'package:flutter/material.dart';

import '../presentation/home_screen/utils/SVCommon.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({Key? key, required this.child}) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  late Timer _timer;
  double _gradientOffset = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), _updateGradient);
  }

  void _updateGradient(Timer timer) {
    setState(() {
      _gradientOffset += 0.01;
      if (_gradientOffset >= 1) {
        _gradientOffset = 0;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(_gradientOffset, 0),
                end: Alignment(_gradientOffset - 4, 0),
                colors: [svGetScaffoldColor(),svGetScaffoldColor()],
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
