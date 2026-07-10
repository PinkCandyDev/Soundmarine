import 'package:flutter/material.dart';

/// Builds a [PageRouteBuilder] that slides a page in from the bottom.
class PageSlideTransition extends PageRouteBuilder {
  final Widget child;

  PageSlideTransition({required this.child})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: end).animate(curve),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}
