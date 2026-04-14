import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../config/api_config.dart';
import '../services/auth_service.dart';

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

  /// Stream d'événements de statut de commande (déclenché par FCM foreground).
  /// OrdersScreen écoute ce stream pour se rafraîchir instantanément.
  static final StreamController<Map<String, dynamic>> _orderEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get orderEvents =>
      _orderEventController.stream;

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

      // Envoyer le token au backend si l'utilisateur est connecté
      if (token != null) {
        await registerTokenToBackend(token);
      }

      // Rafraîchir le token si renouvelé
      messaging.onTokenRefresh.listen((newToken) {
        registerTokenToBackend(newToken);
      });

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

    // Si c'est un événement de commande, émettre sur le stream
    final data = message.data;
    if (data['type'] == 'order_status_changed' || data['type'] == 'new_order') {
      _orderEventController.add(data);
    }

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

  /// Enregistre le token FCM au backend Laravel (POST /api/auth/device-token).
  /// Silencieux si l'utilisateur n'est pas connecté.
  static Future<void> registerTokenToBackend(String token) async {
    try {
      final authToken = await AuthService.getToken();
      if (authToken == null) return; // Guest — pas de token à enregistrer

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (kDebugMode) {
        debugPrint('📲 FCM token backend: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ FCM token backend failed: $e');
    }
  }

  /// Efface le token FCM du backend à la déconnexion.
  static Future<void> unregisterTokenFromBackend() async {
    try {
      final authToken = await AuthService.getToken();
      if (authToken == null) return;

      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/auth/device-token'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ FCM token unregister failed: $e');
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
