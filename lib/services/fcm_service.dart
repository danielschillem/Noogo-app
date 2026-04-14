import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handler exécuté dans un isolate séparé (background).
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Les données sont disponibles dans message.data
  if (kDebugMode) debugPrint('FCM background: ${message.notification?.title}');
}

/// Service Firebase Cloud Messaging.
/// Initialise les permissions, le canal Android et les listeners de messages.
class FCMService {
  static bool _initialized = false;

  static final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'noogo_high_importance',
    'Notifications Noogo',
    description: 'Commandes, promotions et alertes importantes',
    importance: Importance.high,
  );

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final messaging = FirebaseMessaging.instance;

      // Permissions (iOS + Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        debugPrint('📲 FCM permission: ${settings.authorizationStatus.name}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) debugPrint('📲 FCM notifications refusées');
        return;
      }

      // Créer le canal Android haute importance
      await _localNotifs
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Init flutter_local_notifications
      await _localNotifs.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false, // Déjà demandé via FCM
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );

      // Handler background
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      // Messages reçus quand l'app est au premier plan
      FirebaseMessaging.onMessage.listen(_onForeground);

      // App ouverte depuis une notification (background → foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        if (kDebugMode) debugPrint('📲 App ouverte depuis FCM: ${msg.data}');
      });

      // Token (pour l'envoyer au backend)
      final token = await messaging.getToken();
      if (kDebugMode) debugPrint('📲 FCM Token: $token');

      // Topic global pour les notifications broadcast
      await messaging.subscribeToTopic('all_users');

      _initialized = true;
      if (kDebugMode) debugPrint('✅ FCM initialisé');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ FCM init échoué: $e');
    }
  }

  static Future<void> _onForeground(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    if (kDebugMode) debugPrint('📲 FCM foreground: ${notif.title}');

    await _localNotifs.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Retourne le token FCM courant (à envoyer au backend pour les push ciblés).
  static Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Abonne l'utilisateur à un topic (ex: restaurant_{id}).
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      if (kDebugMode) debugPrint('📲 Abonné au topic: $topic');
    } catch (_) {}
  }

  /// Désabonne l'utilisateur d'un topic.
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (_) {}
  }
}
