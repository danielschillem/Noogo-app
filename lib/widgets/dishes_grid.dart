import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/dish.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../config/api_config.dart'; // ✅ AJOUT

class DishesGrid extends StatelessWidget {
  final List<Dish> dishes;
  final Function(Dish)? onDishTap;
  final bool showDebugInfo; // ✅ AJOUT : Pour le débogage

  const DishesGrid({
    super.key,
    required this.dishes,
    this.onDishTap,
    this.showDebugInfo = false, // ✅ AJOUT
  });

  /// ✅ AMÉLIORATION : Utilise ApiConfig pour construire les URLs
  Widget _buildImage(String? imagePath, {double? width, double? height, BoxFit? fit}) {
    // Construire l'URL complète via ApiConfig
    final imageUrl = ApiConfig.getFullImageUrl(imagePath);

    if (showDebugInfo) {
      debugPrint('🖼️ DishesGrid - Image');
      debugPrint('   Path: $imagePath');
      debugPrint('   URL: $imageUrl');
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,

      // ✅ AMÉLIORATION : Meilleur placeholder
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: AppColors.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chargement...',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),

      // ✅ AMÉLIORATION : Meilleur errorWidget avec logs
      errorWidget: (context, url, error) {
        if (showDebugInfo) {
          debugPrint('❌ Erreur chargement image');
          debugPrint('   URL: $url');
          debugPrint('   Erreur: $error');
        }

        return Container(
          width: width,
          height: height,
          color: AppColors.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                color: AppColors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                'Image\nindisponible',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              if (showDebugInfo) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    url,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: 8,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (dishes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun plat disponible',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nos plats',
                style: AppTextStyles.heading3,
              ),
              // ✅ AJOUT : Badge avec nombre de plats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dishes.length} plat${dishes.length > 1 ? 's' : ''}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16, // ✅ CORRECTION : 100 était trop grand
            ),
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final dish = dishes[index];
              return _AnimatedDishCard(
                dish: dish,
                onTap: () => onDishTap?.call(dish),
                buildImage: _buildImage,
                index: index,
                showDebugInfo: showDebugInfo, // ✅ AJOUT
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnimatedDishCard extends StatefulWidget {
  final Dish dish;
  final VoidCallback? onTap;
  final int index;
  final bool showDebugInfo; // ✅ AJOUT
  final Widget Function(String? imagePath, {double? width, double? height, BoxFit? fit}) buildImage;

  const _AnimatedDishCard({
    required this.dish,
    required this.onTap,
    required this.buildImage,
    required this.index,
    this.showDebugInfo = false, // ✅ AJOUT
  });

  @override
  State<_AnimatedDishCard> createState() => _AnimatedDishCardState();
}

class _AnimatedDishCardState extends State<_AnimatedDishCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dish = widget.dish;

    return AnimatedScale(
      scale: _hovered ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: 1,
        duration: Duration(milliseconds: 400 + (widget.index * 50)),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _hovered = true),
          onTapUp: (_) {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) setState(() => _hovered = false);
              widget.onTap?.call();
            });
          },
          onTapCancel: () {
            if (mounted) setState(() => _hovered = false);
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _hovered
                        ? AppColors.primary.withOpacity(0.25)
                        : AppColors.shadowColor.withOpacity(0.15),
                    blurRadius: _hovered ? 10 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖼️ Image du plat
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      child: Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: widget.buildImage(
                              dish.imageUrl, // ✅ Maintenant gère tous les formats
                              fit: BoxFit.cover,
                            ),
                          ),

                          // ✅ AMÉLIORATION : Badge plat du jour plus visible
                          if (dish.isDishOfTheDay)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.secondary,
                                      AppColors.secondary.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 12,
                                      color: AppColors.textLight,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Plat du jour',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ✅ AMÉLIORATION : Overlay "Non disponible" plus clair
                          if (!dish.isAvailable)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(14),
                                    topRight: Radius.circular(14),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.block,
                                        color: AppColors.textLight,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Non disponible',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 📝 Infos du plat
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dish.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: dish.isAvailable
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (dish.description.isNotEmpty)
                            Expanded(
                              child: Text(
                                dish.description,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2, // ✅ AMÉLIORATION : 2 lignes au lieu de 1
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ✅ AMÉLIORATION : Prix plus visible
                              Text(
                                dish.formattedPrice,
                                style: AppTextStyles.price.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: dish.isAvailable
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              if (dish.preparationTime > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${dish.preparationTime}min',
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}