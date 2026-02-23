import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_colors.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const AnimatedSplashScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _iconsController;
  late AnimationController _pulseController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _pulseAnimation;

  // Icônes qui tournent autour du logo
  final List<IconData> _foodIcons = [
    Icons.restaurant_menu,
    Icons.local_pizza,
    Icons.lunch_dining,
    Icons.local_cafe,
    Icons.cake,
    Icons.local_bar,
    Icons.dinner_dining,
    Icons.fastfood,
  ];

  @override
  void initState() {
    super.initState();

    // Animation principale (logo)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Animation des icônes qui tournent
    _iconsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Animation de pulsation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Logo scale
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Logo opacity
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Démarrer l'animation
    _mainController.forward();

    // Appeler le callback après l'animation
    Future.delayed(const Duration(milliseconds: 10000), () {
      if (mounted) {
        widget.onInitializationComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _iconsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.primary,
        child: Stack(
          children: [
            // Icônes qui tournent en arrière-plan
            _buildRotatingIcons(),

            // Logo central
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacityAnimation.value,
                    child: Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: _buildLogo(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Image.asset(
                  'assets/images/03.png', // Votre logo
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRotatingIcons() {
    return AnimatedBuilder(
      animation: _iconsController,
      builder: (context, child) {
        return Stack(
          children: List.generate(_foodIcons.length, (index) {
            final angle = (2 * math.pi / _foodIcons.length) * index +
                (_iconsController.value * 2 * math.pi);
            final radius = MediaQuery.of(context).size.width * 0.35;
            final x = MediaQuery.of(context).size.width / 2 +
                radius * math.cos(angle) -
                30;
            final y = MediaQuery.of(context).size.height / 2 +
                radius * math.sin(angle) -
                30;

            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: 0.3,
                child: Transform.rotate(
                  angle: -angle, // Contre-rotation pour garder les icônes droites
                  child: Icon(
                    _foodIcons[index],
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}