import 'package:flutter/material.dart';

class AppAnimations {
  // Durées d'animation
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Courbes d'animation
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve sharpCurve = Curves.easeInOutQuart;

  // Transitions de page personnalisées
  static PageRouteBuilder<T> slideTransition<T>(
    Widget page, {
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Duration duration = medium,
    Curve curve = defaultCurve,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: end,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<T> fadeTransition<T>(
    Widget page, {
    Duration duration = medium,
    Curve curve = defaultCurve,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<T> scaleTransition<T>(
    Widget page, {
    double begin = 0.0,
    double end = 1.0,
    Duration duration = medium,
    Curve curve = defaultCurve,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: begin,
            end: end,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      },
    );
  }

  // Animations de widgets
  static Widget slideInFromBottom(
    Widget child, {
    Duration duration = medium,
    Curve curve = defaultCurve,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration + delay,
      tween: Tween<double>(begin: 1.0, end: 0.0),
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value * 50),
          child: Opacity(
            opacity: 1 - value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget slideInFromRight(
    Widget child, {
    Duration duration = medium,
    Curve curve = defaultCurve,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration + delay,
      tween: Tween<double>(begin: 1.0, end: 0.0),
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value * 50, 0),
          child: Opacity(
            opacity: 1 - value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget fadeIn(
    Widget child, {
    Duration duration = medium,
    Curve curve = defaultCurve,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration + delay,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget scaleIn(
    Widget child, {
    Duration duration = medium,
    Curve curve = bounceCurve,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration + delay,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  // Animation de chargement personnalisée
  static Widget loadingAnimation({
    Color color = const Color(0xFF00C851),
    double size = 40.0,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 3.0,
      ),
    );
  }

  // Animation de pulsation
  static Widget pulseAnimation(
    Widget child, {
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween<double>(begin: minScale, end: maxScale),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      onEnd: () {
        // Répéter l'animation
      },
      child: child,
    );
  }

  // Animation de rebond pour les boutons
  static Widget bounceOnTap(
    Widget child, {
    VoidCallback? onTap,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween<double>(begin: 1.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTapDown: (_) {
              // Réduire la taille
            },
            onTapUp: (_) {
              // Restaurer la taille
              onTap?.call();
            },
            onTapCancel: () {
              // Restaurer la taille
            },
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Staggered animations pour les listes
  static Widget staggeredListAnimation(
    Widget child,
    int index, {
    Duration duration = medium,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration + (delay * index),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 50),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

