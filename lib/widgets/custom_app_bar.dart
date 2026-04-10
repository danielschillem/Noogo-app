import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/restaurant_provider.dart';
import '../screens/notification_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotificationBadge;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showNotificationBadge = true, // ✅ Activé par défaut
    this.notificationCount = 0,
    this.onNotificationTap,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 4,
      shadowColor: AppColors.shadowColor,
      // gradient background with rounded bottom corners
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(14)),
        ),
      ),
      // Bouton retour optionnel
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      )
          : null,
      automaticallyImplyLeading: showBackButton,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // ✅ Icône de notification dynamique avec Provider
        Consumer<RestaurantProvider>(
          builder: (context, provider, child) {
            // Si showNotificationBadge est false, ne rien afficher
            if (!showNotificationBadge) {
              return const SizedBox(width: 8);
            }

            // Utiliser le compteur du provider ou le compteur manuel
            final count = notificationCount > 0
                ? notificationCount
                : provider.unreadNotificationsCount;

            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: onNotificationTap ??
                            () {
                          // Navigation par défaut vers l'écran des notifications
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                  ),
                  // Badge avec compteur
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}