import 'package:flutter/material.dart';

/// A simpler utility class for managing animations throughout the app
class AppAnimations {
  /// Default duration for most animations
  static const Duration defaultDuration = Duration(milliseconds: 300);
  
  /// Longer duration for more complex animations
  static const Duration longDuration = Duration(milliseconds: 500);
  
  /// Shorter duration for micro-interactions
  static const Duration quickDuration = Duration(milliseconds: 150);

  /// Standard curve for most animations
  static const Curve defaultCurve = Curves.easeInOutCubic;
  
  /// Route transition for page navigation
  static Route<T> pageTransition<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: defaultCurve,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: defaultDuration,
    );
  }
  
  /// Create a simple fade transition animation
  static Widget fadeAnimation({
    required Widget child,
    required bool animate,
    Curve curve = Curves.easeOut,
    Duration duration = const Duration(milliseconds: 400),
    double begin = 0.0,
    double end = 1.0,
  }) {
    if (!animate) return child;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }
  
  /// Create a scale animation
  static Widget scaleAnimation({
    required Widget child,
    required bool animate,
    Curve curve = Curves.easeOut,
    Duration duration = const Duration(milliseconds: 400),
    double begin = 0.8,
    double end = 1.0,
  }) {
    if (!animate) return child;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }
}

/// Simple animated list item for staggered list animations
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final bool animate;
  
  const AnimatedListItem({
    Key? key,
    required this.child,
    required this.index,
    this.animate = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), 
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Page transitions to use with Navigator.push
class AppPageTransitions {
  /// Slide transition from right
  static PageRouteBuilder slideFromRight({required Widget page}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        
        var tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: curve));
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  /// Fade transition
  static PageRouteBuilder fadeTransition({required Widget page}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}