import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../config/api_config.dart';

/// Canal Android dédié aux alertes serveur.
const AndroidNotificationChannel _waiterChannel = AndroidNotificationChannel(
  'noogo_waiter_orders',
  'Alertes commandes serveur',
  description: 'Alerte sonore quand une commande arrive ou est prête',
  importance: Importance.max,
  sound: RawResourceAndroidNotificationSound('delivery_alert'),
  enableVibration: true,
  playSound: true,
);

/// Événement commande (nouvelle commande arrivée ou statut changé).
class WaiterOrderEvent {
  final String type; // 'new_order' | 'order_updated' | 'order_ready'
  final int orderId;
  final String? status;
  final String? tableNumber;
  final String? orderType;

  const WaiterOrderEvent({
    required this.type,
    required this.orderId,
    this.status,
    this.tableNumber,
    this.orderType,
  });

  factory WaiterOrderEvent.fromData(Map<String, dynamic> data) {
    return WaiterOrderEvent(
      type: data['type']?.toString() ?? 'order_updated',
      orderId: int.tryParse(data['order_id']?.toString() ?? '') ?? 0,
      status: data['status']?.toString(),
      tableNumber: data['table_number']?.toString(),
      orderType: data['order_type']?.toString(),
    );
  }

  bool get isNewOrder => type == 'new_order';
  bool get isReady => type == 'order_ready' || status == 'ready';
}

/// Service de notification du serveur.
///
/// - Canal Android haute priorité avec son `delivery_alert.wav`
/// - Écoute Pusher `private-restaurant.{restaurantId}` (temps réel)
/// - Écoute FCM foreground (fallback)
/// - Expose [orderEventStream] pour rafraîchir l'UI et afficher les alertes
class WaiterNotificationService {
  static final WaiterNotificationService _instance =
      WaiterNotificationService._internal();
  factory WaiterNotificationService() => _instance;
  WaiterNotificationService._internal();

  static WaiterNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();
  PusherChannelsFlutter? _pusher;

  bool _initialized = false;
  int? _restaurantId;
  String? _authToken;

  final StreamController<WaiterOrderEvent> _orderController =
      StreamController<WaiterOrderEvent>.broadcast();

  /// Stream d'événements commandes en temps réel.
  Stream<WaiterOrderEvent> get orderEventStream => _orderController.stream;

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> init({
    required int restaurantId,
    required String authToken,
  }) async {
    if (_initialized) {
      // Re-init if restaurant changed
      if (_restaurantId != restaurantId) {
        await dispose();
        _initialized = false;
      } else {
        return;
      }
    }
    _restaurantId = restaurantId;
    _authToken = authToken;

    await _setupLocalNotifications();
    await _connectPusher();
    _listenFcmForeground();

    _initialized = true;
    debugPrint(
        '✅ WaiterNotificationService initialisé (restaurant=$restaurantId)');
  }

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
    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_waiterChannel);
  }

  Future<void> _connectPusher() async {
    final key = ApiConfig.pusherKey;
    final cluster = ApiConfig.pusherCluster;
    if (key.isEmpty || _restaurantId == null) {
      debugPrint('⚠️ WaiterNotif: Pusher key vide ou restaurantId null');
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
          if (kDebugMode) {
            debugPrint('🔌 Pusher waiter: $previous→$current');
          }
        },
        onError: (message, code, error) {
          if (kDebugMode) debugPrint('❌ Pusher waiter error: $message');
        },
        onSubscriptionError: (message, error) {
          if (kDebugMode) debugPrint('❌ Pusher waiter sub error: $message');
        },
      );
      await _pusher!.connect();

      final channelName = 'private-restaurant.$_restaurantId';
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: _onPusherEvent,
      );
      if (kDebugMode) {
        debugPrint('✅ Pusher waiter souscrit: $channelName');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Pusher waiter connect failed: $e');
    }
  }

  void _onPusherEvent(PusherEvent event) {
    if (kDebugMode) {
      debugPrint('📡 Pusher waiter event: ${event.eventName}');
    }
    final raw = event.data;
    if (raw == null) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final eventName = event.eventName;

      if (eventName == 'order.created' || eventName == 'new_order') {
        data['type'] = 'new_order';
        _handleOrderEvent(data);
      } else if (eventName == 'order.updated') {
        _handleOrderEvent(data);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Pusher event parse: $e');
    }
  }

  void _listenFcmForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final type = message.data['type'];
      if (type == 'new_order' ||
          type == 'order_ready' ||
          type == 'order_status_changed') {
        _handleOrderEvent(message.data);
      }
    });
  }

  // ─── Handler ───────────────────────────────────────────────────────────────

  void _handleOrderEvent(Map<String, dynamic> data) {
    final event = WaiterOrderEvent.fromData(data);
    if (kDebugMode)
      debugPrint('🔔 WaiterEvent: ${event.type} order=${event.orderId}');

    // Émettre sur le stream → rafraîchir l'UI
    _orderController.add(event);

    // Notification locale
    if (event.isNewOrder) {
      _showNotification(
        id: event.orderId,
        title: '🍽️ Nouvelle commande #${event.orderId}',
        body: event.tableNumber != null
            ? 'Table ${event.tableNumber} — commande en attente'
            : 'Commande en attente de confirmation',
      );
    } else if (event.isReady) {
      _showNotification(
        id: event.orderId + 10000,
        title: '🔔 Commande #${event.orderId} prête !',
        body: event.tableNumber != null
            ? 'Table ${event.tableNumber} — à servir maintenant'
            : 'La commande est prête à être servie',
      );
    }
  }

  void _showNotification({
    required int id,
    required String title,
    required String body,
  }) {
    _localNotifs.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _waiterChannel.id,
          _waiterChannel.name,
          channelDescription: _waiterChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          sound: _waiterChannel.sound,
          enableVibration: true,
          playSound: true,
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

  // ─── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    try {
      await _pusher?.unsubscribe(
          channelName: 'private-restaurant.$_restaurantId');
      await _pusher?.disconnect();
      _pusher = null;
    } catch (_) {}
    _initialized = false;
  }
}
