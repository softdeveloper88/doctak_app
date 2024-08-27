import 'package:flutter/material.dart';

enum PageTransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  fade,
  scale,
  rotate,
  noTransition,
}

class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final PageTransitionType transitionType;

  CustomPageRoute({
    required this.page,
    required this.transitionType,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (transitionType) {
        case PageTransitionType.slideFromRight:
          return _slideTransition(animation, child, const Offset(1, 0));
        case PageTransitionType.slideFromLeft:
          return _slideTransition(animation, child, const Offset(-1, 0));
        case PageTransitionType.slideFromBottom:
          return _slideTransition(animation, child, const Offset(0, 1));
        case PageTransitionType.slideFromTop:
          return _slideTransition(animation, child, const Offset(0, -1));
        case PageTransitionType.fade:
          return FadeTransition(opacity: animation, child: child);
        case PageTransitionType.scale:
          return ScaleTransition(scale: animation, child: child);
        case PageTransitionType.rotate:
          return RotationTransition(turns: animation, child: child);
        case PageTransitionType.noTransition:
        default:
          return child;
      }
    },
  );

  static SlideTransition _slideTransition(
      Animation<double> animation, Widget child, Offset begin) {
    final tween = Tween(begin: begin, end: Offset.zero)
        .chain(CurveTween(curve: Curves.ease));
    final offsetAnimation = animation.drive(tween);
    return SlideTransition(position: offsetAnimation, child: child);
  }
}
