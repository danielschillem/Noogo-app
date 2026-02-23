import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

class NotificationService {
  static const String _notificationsKey = 'notifications';
  static const int _maxNotifications = 100; // Limite pour éviter une liste trop longue

  // Sauvegarder les notifications
  static Future<void> saveNotifications(List<AppNotification> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Limiter le nombre de notifications sauvegardées
      final limitedNotifications = notifications.take(_maxNotifications).toList();

      final notificationsJson = limitedNotifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(notificationsJson));
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des notifications: $e');
    }
  }

  // Charger les notifications
  static Future<List<AppNotification>> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsString = prefs.getString(_notificationsKey);

      if (notificationsString == null || notificationsString.isEmpty) {
        return [];
      }

      final List<dynamic> notificationsJson = jsonDecode(notificationsString);
      return notificationsJson
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Erreur lors du chargement des notifications: $e');
      return [];
    }
  }

  // Ajouter une notification (depuis le backend ou locale)
  static Future<void> addNotification(AppNotification notification) async {
    try {
      final notifications = await loadNotifications();

      // Vérifier si la notification existe déjà (éviter les doublons)
      final exists = notifications.any((n) => n.id == notification.id);
      if (exists) {
        print('⚠️ Notification déjà existante: ${notification.id}');
        return;
      }

      notifications.insert(0, notification); // Ajouter en premier (plus récent)
      await saveNotifications(notifications);

      print('✅ Notification ajoutée: ${notification.title}');
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de notification: $e');
    }
  }

  // Créer une notification depuis les données du backend
  static Future<void> addNotificationFromBackend(Map<String, dynamic> data) async {
    try {
      // Nettoyer les données pour éviter les erreurs de type
      final cleanData = _cleanNotificationData(data);

      // Extraire les informations
      final id = cleanData['id']?.toString() ??
          cleanData['notification_id']?.toString() ??
          'notif_${DateTime.now().millisecondsSinceEpoch}';

      final title = cleanData['title']?.toString() ??
          cleanData['notification_title']?.toString() ??
          'Nouvelle notification';

      final body = cleanData['body']?.toString() ??
          cleanData['message']?.toString() ??
          cleanData['notification_body']?.toString() ??
          '';

      final type = cleanData['type']?.toString() ??
          cleanData['notification_type']?.toString() ??
          'general';

      // Parser la date avec gestion d'erreur
      DateTime timestamp;
      try {
        if (cleanData['timestamp'] != null) {
          timestamp = DateTime.parse(cleanData['timestamp'].toString());
        } else if (cleanData['created_at'] != null) {
          timestamp = DateTime.parse(cleanData['created_at'].toString());
        } else {
          timestamp = DateTime.now();
        }
      } catch (e) {
        print('⚠️ Erreur de parsing de date: $e');
        timestamp = DateTime.now();
      }

      // Créer la notification
      final notification = AppNotification(
        id: id,
        title: title,
        body: body,
        timestamp: timestamp,
        type: type,
        data: cleanData,
        isRead: false,
      );

      await addNotification(notification);

      print('✅ Notification backend ajoutée: $title');
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la création de notification depuis backend: $e');
      print('Stack trace: $stackTrace');
      print('Données reçues: $data');
    }
  }

  // Nettoyer les données pour éviter les erreurs de type
  static Map<String, dynamic> _cleanNotificationData(Map<String, dynamic> data) {
    final cleaned = <String, dynamic>{};

    data.forEach((key, value) {
      try {
        // Convertir tous les types numériques en String pour éviter les erreurs
        if (value is num) {
          cleaned[key] = value.toString();
        } else if (value is Map) {
          cleaned[key] = _cleanNotificationData(Map<String, dynamic>.from(value));
        } else if (value is List) {
          cleaned[key] = value.map((item) {
            if (item is Map) {
              return _cleanNotificationData(Map<String, dynamic>.from(item));
            }
            return item;
          }).toList();
        } else {
          cleaned[key] = value;
        }
      } catch (e) {
        print('⚠️ Erreur nettoyage clé $key: $e');
        cleaned[key] = value?.toString();
      }
    });

    return cleaned;
  }

  // Marquer comme lue
  static Future<void> markAsRead(String notificationId) async {
    try {
      final notifications = await loadNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);

      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        await saveNotifications(notifications);
        print('✅ Notification marquée comme lue: $notificationId');
      }
    } catch (e) {
      print('❌ Erreur lors du marquage comme lu: $e');
    }
  }

  // Marquer toutes comme lues
  static Future<void> markAllAsRead() async {
    try {
      final notifications = await loadNotifications();
      final updatedNotifications = notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      await saveNotifications(updatedNotifications);
      print('✅ Toutes les notifications marquées comme lues');
    } catch (e) {
      print('❌ Erreur lors du marquage global: $e');
    }
  }

  // Supprimer une notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = await loadNotifications();
      notifications.removeWhere((n) => n.id == notificationId);
      await saveNotifications(notifications);
      print('✅ Notification supprimée: $notificationId');
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
    }
  }

  // Supprimer toutes les notifications
  static Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      print('✅ Toutes les notifications supprimées');
    } catch (e) {
      print('❌ Erreur lors de la suppression globale: $e');
    }
  }

  // Compter les non lues
  static Future<int> getUnreadCount() async {
    try {
      final notifications = await loadNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('❌ Erreur lors du comptage: $e');
      return 0;
    }
  }

  // Supprimer les anciennes notifications (> 30 jours)
  static Future<void> cleanOldNotifications({int daysToKeep = 30}) async {
    try {
      final notifications = await loadNotifications();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final recentNotifications = notifications
          .where((n) => n.timestamp.isAfter(cutoffDate))
          .toList();

      await saveNotifications(recentNotifications);

      final deletedCount = notifications.length - recentNotifications.length;
      if (deletedCount > 0) {
        print('✅ $deletedCount anciennes notifications supprimées');
      }
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }

  // Créer une notification de test
  static AppNotification createTestNotification(String type) {
    final now = DateTime.now();
    final id = 'test_${now.millisecondsSinceEpoch}';

    switch (type) {
      case 'order':
        return AppNotification(
          id: id,
          title: 'Commande confirmée',
          body: 'Votre commande #${now.millisecondsSinceEpoch} a été confirmée et est en préparation.',
          timestamp: now,
          type: 'order',
          data: {'orderId': '${now.millisecondsSinceEpoch}'},
        );

      case 'delivery':
        return AppNotification(
          id: id,
          title: 'Livraison en cours',
          body: 'Votre livreur est en route ! Temps estimé : 15 minutes.',
          timestamp: now,
          type: 'delivery',
        );

      case 'promo':
        return AppNotification(
          id: id,
          title: 'Offre spéciale 🎉',
          body: '-20% sur tous les plats aujourd\'hui ! Ne ratez pas cette occasion.',
          timestamp: now,
          type: 'promo',
        );

      case 'ready':
        return AppNotification(
          id: id,
          title: 'Commande prête ✅',
          body: 'Votre commande est prête pour la livraison !',
          timestamp: now,
          type: 'order',
          data: {'status': 'ready'},
        );

      case 'cancelled':
        return AppNotification(
          id: id,
          title: 'Commande annulée',
          body: 'Votre commande a été annulée. Veuillez contacter le support si nécessaire.',
          timestamp: now,
          type: 'order',
          data: {'status': 'cancelled'},
        );

      default:
        return AppNotification(
          id: id,
          title: 'Nouvelle notification',
          body: 'Vous avez une nouvelle notification.',
          timestamp: now,
          type: 'general',
        );
    }
  }
}