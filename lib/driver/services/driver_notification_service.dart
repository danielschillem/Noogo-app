import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../config/api_config.dart';

/// Canal Android dédié aux alertes de livraison — son distinct + haute priorité.
const AndroidNotificationChannel _deliveryChannel = AndroidNotificationChannel(
  'noogo_driver_delivery',
  'Nouvelles livraisons',
  description: 'Alerte sonore quand une livraison est assignée au livreur',
  importance: Importance.max,
  sound: RawResourceAndroidNotificationSound('delivery_alert'),
  enableVibration: true,
  playSound: true,
);

/// Événement émis quand une nouvelle livraison est assignée.
class NewDeliveryEvent {
  final int deliveryId;
  final int orderId;
  final String? customerName;
  final String? address;

  const NewDeliveryEvent({
    required this.deliveryId,
    required this.orderId,
    this.customerName,
    this.address,
  });

  factory NewDeliveryEvent.fromData(Map<String, dynamic> data) {
    return NewDeliveryEvent(
      deliveryId: int.tryParse(data['delivery_id']?.toString() ?? '') ?? 0,
      orderId: int.tryParse(data['order_id']?.toString() ?? '') ?? 0,
      customerName: data['customer_name']?.toString(),
      address: data['address']?.toString(),
    );
  }
}

/// Service de notification du livreur.
///
/// Responsabilités:
/// - Canal Android haute priorité avec son `delivery_alert.wav`
/// - Écoute Pusher canal `private-driver.{userId}` (temps réel)
/// - Écoute FCM foreground (fallback si Pusher déconnecté)
/// - Expose [newDeliveryStream] pour déclencher le dialog in-app
class DriverNotificationService {
  static final DriverNotificationService _instance =
      DriverNotificationService._internal();
  factory DriverNotificationService() => _instance;
  DriverNotificationService._internal();

  static DriverNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();
  PusherChannelsFlutter? _pusher;

  bool _initialized = false;
  String? _userId;
  String? _authToken;

  final StreamController<NewDeliveryEvent> _deliveryController =
      StreamController<NewDeliveryEvent>.broadcast();

  /// Stream d'événements "nouvelle livraison assignée".
  /// DriverHomeScreen s'abonne pour afficher le dialog Alert.
  Stream<NewDeliveryEvent> get newDeliveryStream => _deliveryController.stream;

  /// Initialise le service pour un livreur connecté.
  Future<void> init({required String userId, required String authToken}) async {
    if (_initialized) return;
    _userId = userId;
    _authToken = authToken;

    await _setupLocalNotifications();
    await _connectPusher();
    _listenFcmForeground();

    _initialized = true;
    if (kDebugMode)
      debugPrint('✅ DriverNotificationService initialisé (user=$userId)');
  }

  /// Démarre l'écoute sans Pusher (mode dégradé, FCM seulement).
  Future<void> initFcmOnly() async {
    if (_initialized) return;
    await _setupLocalNotifications();
    _listenFcmForeground();
    _initialized = true;
  }

  // ─── Setup ─────────────────────────────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    await _localNotifs.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    // Créer le canal Android dédié livraison
    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_deliveryChannel);
  }

  Future<void> _connectPusher() async {
    final key = ApiConfig.pusherKey;
    final cluster = ApiConfig.pusherCluster;
    if (key.isEmpty) {
      if (kDebugMode)
        debugPrint('⚠️ DriverNotif: Pusher key vide, mode FCM only');
      return;
    }

    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher!.init(
        apiKey: key,
        cluster: cluster,
        useTLS: true,
        authEndpoint: ApiConfig.pusherAuthEndpoint,
        authParams: {
          'headers': {'Authorization': 'Bearer $_authToken'},
        },
        onConnectionStateChange: (current, previous) {
          if (kDebugMode) debugPrint('🔌 Pusher driver: $previous→$current');
        },
        onError: (message, code, error) {
          if (kDebugMode) debugPrint('❌ Pusher driver error: $message');
        },
        onSubscriptionError: (message, error) {
          if (kDebugMode) debugPrint('❌ Pusher sub error: $message');
        },
      );
      await _pusher!.connect();

      // Canal privé du livreur: private-driver.{userId}
      final channelName = 'private-driver.$_userId';
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: _onPusherEvent,
      );
      if (kDebugMode) debugPrint('✅ Pusher driver souscrit: $channelName');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Pusher driver connect failed: $e');
    }
  }

  void _onPusherEvent(PusherEvent event) {
    if (kDebugMode) debugPrint('📡 Pusher driver event: ${event.eventName}');
    if (event.eventName == 'delivery.assigned') {
      final raw = event.data;
      if (raw == null) return;
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _handleNewDelivery(data);
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Pusher event parse: $e');
      }
    }
  }

  void _listenFcmForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final type = message.data['type'];
      if (type == 'delivery.assigned') {
        _handleNewDelivery(message.data);
      }
    });
  }

  // ─── Handler commun ────────────────────────────────────────────────────────

  void _handleNewDelivery(Map<String, dynamic> data) {
    if (kDebugMode) debugPrint('🚚 Nouvelle livraison: $data');

    final event = NewDeliveryEvent.fromData(data);

    // 1. Émettre sur le stream → dialog in-app
    _deliveryController.add(event);

    // 2. Notification locale avec son delivery_alert
    final orderId = event.orderId;
    final customer = event.customerName ?? 'Client';
    _localNotifs.show(
      event.deliveryId,
      '🚚 Nouvelle livraison !',
      'Commande #$orderId — $customer',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _deliveryChannel.id,
          _deliveryChannel.name,
          channelDescription: _deliveryChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          sound: const RawResourceAndroidNotificationSound('delivery_alert'),
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF00C851),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'delivery_alert.wav',
        ),
      ),
    );
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _pusher?.disconnect();
    await _deliveryController.close();
    _initialized = false;
  }
}
