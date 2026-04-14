import 'package:flutter/material.dart';

/// Widget de placeholder animé (shimmer) pendant le chargement.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height, this.width, this.radius});

  final double? height;
  final double? width;
  final double? radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.04, end: 0.10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.radius ?? 12),
          ),
        );
      },
    );
  }
}

/// Skeleton circulaire (avatar, icône).
class CircleSkeleton extends StatefulWidget {
  const CircleSkeleton({super.key, this.size = 40});

  final double size;

  @override
  State<CircleSkeleton> createState() => _CircleSkeletonState();
}

class _CircleSkeletonState extends State<CircleSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.04, end: 0.10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Bloc de skeleton pour une carte plat entière.
class DishCardSkeleton extends StatelessWidget {
  const DishCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 100, radius: 12),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 12, width: MediaQuery.sizeOf(context).width),
                const SizedBox(height: 6),
                const Skeleton(height: 10, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
