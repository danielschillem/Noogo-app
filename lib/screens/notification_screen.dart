import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../services/restaurant_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Notifications',
        showNotificationBadge: false, // ✅ Cacher l'icône sur cette page
        showBackButton: true, // ✅ Afficher le bouton retour
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyNotifications();
          }

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: Column(
              children: [
                // Titre de la page
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Notifications',
                        style: AppTextStyles.heading1,
                      ),
                      const Spacer(),
                      if (provider.unreadNotificationsCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${provider.unreadNotificationsCount} non lue${provider.unreadNotificationsCount > 1 ? 's' : ''}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Actions rapides
                if (provider.unreadNotificationsCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _markAllAsRead(provider),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                            child: const Text('Tout marquer comme lu'),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Liste des notifications
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = provider.notifications[index];
                      return _buildNotificationCard(notification, provider);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune notification',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore de notifications',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      AppNotification notification, RestaurantProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.cardBackground
            : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead
            ? null
            : Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
            _getNotificationIconColor(notification.title).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getNotificationIcon(notification.title),
            color: _getNotificationIconColor(notification.title),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: AppTextStyles.bodySmall.copyWith(
                color: notification.isRead
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(notification.timestamp),
              style: AppTextStyles.caption,
            ),
          ],
        ),
        onTap: () => _onNotificationTap(notification, provider),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onSelected: (value) => _onMenuSelected(value, notification, provider),
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read, size: 18),
                    SizedBox(width: 8),
                    Text('Marquer comme lu'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String title) {
    if (title.toLowerCase().contains('commande')) {
      return Icons.receipt_long;
    } else if (title.toLowerCase().contains('livraison')) {
      return Icons.delivery_dining;
    } else if (title.toLowerCase().contains('offre') ||
        title.toLowerCase().contains('promotion')) {
      return Icons.local_offer;
    } else if (title.toLowerCase().contains('paiement')) {
      return Icons.payment;
    } else {
      return Icons.notifications;
    }
  }

  Color _getNotificationIconColor(String title) {
    if (title.toLowerCase().contains('commande')) {
      return AppColors.primary;
    } else if (title.toLowerCase().contains('livraison')) {
      return AppColors.info;
    } else if (title.toLowerCase().contains('paiement')) {
      return AppColors.success;
    } else if (title.toLowerCase().contains('offre') ||
        title.toLowerCase().contains('promotion')) {
      return AppColors.secondary;
    } else {
      return AppColors.textSecondary;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _onNotificationTap(
      AppNotification notification, RestaurantProvider provider) {
    if (!notification.isRead) {
      provider.markNotificationAsRead(notification.id);
    }

    // Naviguer selon le type de notification
    if (notification.title.toLowerCase().contains('commande')) {
      provider.setNavIndex(3); // Naviguer vers les commandes
      Navigator.pop(context);
    }
  }

  void _onMenuSelected(
      String value, AppNotification notification, RestaurantProvider provider) {
    switch (value) {
      case 'mark_read':
        provider.markNotificationAsRead(notification.id);
        break;
      case 'delete':
        _confirmDeleteNotification(notification, provider);
        break;
    }
  }

  void _confirmDeleteNotification(
      AppNotification notification, RestaurantProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la notification'),
        content: const Text('Voulez-vous supprimer cette notification ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Ici, vous pourriez appeler une méthode pour supprimer la notification
              // provider.deleteNotification(notification.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification supprimée'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead(RestaurantProvider provider) {
    for (final notification in provider.notifications) {
      if (!notification.isRead) {
        provider.markNotificationAsRead(notification.id);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications ont été marquées comme lues'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}