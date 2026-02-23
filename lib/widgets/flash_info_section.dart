import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/flash_info.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class FlashInfoSection extends StatelessWidget {
  final List<FlashInfo> flashInfos;
  final VoidCallback? onOrderPressed;

  const FlashInfoSection({
    super.key,
    required this.flashInfos,
    this.onOrderPressed,
  });

  Color _getBackgroundColor(String colorHex) {
    try {
      String hex = colorHex.trim().replaceAll('#', '').replaceAll(' ', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      }
      return AppColors.secondary;
    } catch (e) {
      return AppColors.secondary;
    }
  }

  Widget _buildImage(String imageUrl, {double? width, double? height, BoxFit? fit}) {
    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.local_offer,
          color: Colors.white.withValues(alpha: 0.5),
          size: 40,
        ),
      );
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_offer,
            color: Colors.white.withValues(alpha: 0.5),
            size: 40,
          ),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_offer,
            color: Colors.white.withValues(alpha: 0.5),
            size: 40,
          ),
        ),
      );
    }
  }

  void _showOfferDetails(BuildContext context, FlashInfo flashInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OfferDetailsSheet(
        flashInfo: flashInfo,
        onOrderPressed: onOrderPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 FlashInfoSection build: ${flashInfos.length} flash infos');

    if (flashInfos.isEmpty) {
      debugPrint('⚠️ FlashInfoSection: Liste vide, widget caché');
      return const SizedBox.shrink();
    }

    debugPrint('✅ FlashInfoSection: Affichage de ${flashInfos.length} flash infos');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Offres spéciales',
                    style: AppTextStyles.heading3,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${flashInfos.length} ${flashInfos.length > 1 ? 'offres' : 'offre'}',
                  style: (AppTextStyles.caption ?? const TextStyle()).copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: flashInfos.length,
            itemBuilder: (context, index) {
              final flashInfo = flashInfos[index];
              return _buildOfferCard(context, flashInfo);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCard(BuildContext context, FlashInfo flashInfo) {
    final bgColor = _getBackgroundColor(flashInfo.backgroundColor);

    return GestureDetector(
      onTap: () => _showOfferDetails(context, flashInfo),
      child: Container(
        width: 340,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Image de fond
              Positioned.fill(
                child: _buildImage(
                  flashInfo.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),

              // Overlay gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Contenu
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges en haut
                      Row(
                        children: [
                          // Badge réduction
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  flashInfo.discountIcon,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  flashInfo.discountBadge,
                                  style: (AppTextStyles.caption ?? const TextStyle()).copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Badge expiration si l'offre expire bientôt
                          if (flashInfo.expiresSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${flashInfo.daysUntilExpiry}j',
                                    style: (AppTextStyles.caption ?? const TextStyle()).copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const Spacer(),

                      // Titre
                      Text(
                        flashInfo.name,
                        style: (AppTextStyles.heading2 ?? const TextStyle()).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Description
                      Text(
                        flashInfo.description,
                        style: (AppTextStyles.bodyMedium ?? const TextStyle()).copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Période de validité si disponible
                      if (flashInfo.validityPeriod != null &&
                          flashInfo.validityPeriod!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  flashInfo.validityPeriod!,
                                  style: (AppTextStyles.caption ?? const TextStyle()).copyWith(
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 08),

                      // Bouton CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showOfferDetails(context, flashInfo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 06),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(06),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Voir les détails',
                                style: (AppTextStyles.buttonMedium ?? const TextStyle()).copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 0),
                              const Icon(
                                Icons.arrow_forward,
                                size: 05,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// SHEET DE DÉTAILS DE L'OFFRE
// ===================================================================

class _OfferDetailsSheet extends StatelessWidget {
  final FlashInfo flashInfo;
  final VoidCallback? onOrderPressed;

  const _OfferDetailsSheet({
    required this.flashInfo,
    this.onOrderPressed,
  });

  Color _getBackgroundColor(String colorHex) {
    try {
      String hex = colorHex.trim().replaceAll('#', '').replaceAll(' ', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      }
      return AppColors.secondary;
    } catch (e) {
      return AppColors.secondary;
    }
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.local_offer,
            size: 80,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        height: 300,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 300,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 300,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(
              Icons.local_offer,
              size: 80,
              color: Colors.grey,
            ),
          ),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        height: 300,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 300,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(
              Icons.local_offer,
              size: 80,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor(flashInfo.backgroundColor);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Barre de drag
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image principale
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: _buildImage(flashInfo.imageUrl),
                          ),

                          // Bouton fermer
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.black87,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),

                          // Badge réduction en overlay
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    flashInfo.discountIcon,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    flashInfo.discountBadge,
                                    style: (AppTextStyles.bodyMedium ?? const TextStyle()).copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Contenu
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre
                            Text(
                              flashInfo.name,
                              style: (AppTextStyles.heading1 ?? const TextStyle()).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Description complète
                            if (flashInfo.description.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: bgColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: bgColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        flashInfo.description,
                                        style: (AppTextStyles.bodyLarge ?? const TextStyle()).copyWith(
                                          color: AppColors.textPrimary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Section: Détails de l'offre
                            Text(
                              'Détails de l\'offre',
                              style: (AppTextStyles.heading3 ?? const TextStyle()).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Période de validité
                            if (flashInfo.validityPeriod != null &&
                                flashInfo.validityPeriod!.isNotEmpty)
                              _buildDetailRow(
                                Icons.schedule,
                                'Période de validité',
                                flashInfo.validityPeriod!,
                                bgColor,
                              ),

                            // Type de réduction
                            if (flashInfo.discountType != null &&
                                flashInfo.discountType!.isNotEmpty)
                              _buildDetailRow(
                                Icons.discount,
                                'Type de réduction',
                                flashInfo.discountType!,
                                bgColor,
                              ),

                            // Valeur de la réduction
                            if (flashInfo.discountValue != null &&
                                flashInfo.discountValue!.isNotEmpty)
                              _buildDetailRow(
                                flashInfo.discountIcon,
                                'Réduction',
                                flashInfo.formattedDiscount,
                                bgColor,
                              ),

                            // Date d'expiration
                            if (flashInfo.expiryDate != null)
                              _buildDetailRow(
                                Icons.event,
                                'Valable jusqu\'au',
                                flashInfo.formattedExpiryDate,
                                bgColor,
                                isWarning: flashInfo.expiresSoon,
                              ),

                            const SizedBox(height: 24),

                            // Conditions d'éligibilité
                            if (flashInfo.conditions != null &&
                                flashInfo.conditions!.isNotEmpty) ...[
                              Text(
                                'Conditions d\'éligibilité',
                                style: (AppTextStyles.heading3 ?? const TextStyle()).copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.rule,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        flashInfo.conditions!,
                                        style: (AppTextStyles.bodyMedium ?? const TextStyle()).copyWith(
                                          color: AppColors.textPrimary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Note importante
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Cette offre est disponible uniquement dans notre restaurant',
                                      style: (AppTextStyles.bodyMedium ?? const TextStyle()).copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bouton d'action fixe en bas
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onOrderPressed?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bgColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        flashInfo.buttonText,
                        style: (AppTextStyles.buttonLarge ?? const TextStyle()).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
      IconData icon,
      String label,
      String value,
      Color color, {
        bool isWarning = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isWarning
                  ? Colors.orange.withValues(alpha: 0.1)
                  : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isWarning ? Colors.orange : color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: (AppTextStyles.bodySmall ?? const TextStyle()).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: (AppTextStyles.bodyMedium ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w600,
                    color: isWarning ? Colors.orange : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}