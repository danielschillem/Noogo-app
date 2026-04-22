import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noogo/config/api_config.dart';

/// Service pour gérer les connexions WebSocket en temps réel avec Pusher
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  PusherChannelsFlutter? _pusher;
  bool _isInitialized = false;
  String? _currentUserId;
  String? _authToken;

  // Liste des canaux souscrits pour debug
  final Set<String> _subscribedChannels = {};

  // Callbacks pour les événements
  Function(Map<String, dynamic>)? onOrderStatusUpdate;
  Function(Map<String, dynamic>)? onNewNotification;
  Function(String)? onConnectionError;
  Function()? onConnected;
  Function()? onDisconnected;

  /// Configuration Pusher - Depuis ApiConfig (.env)
  static String get pusherKey => ApiConfig.pusherKey;
  static String get pusherCluster => ApiConfig.pusherCluster;
  static String get pusherAppId => ApiConfig.pusherAppId;
  static String get authEndpoint => ApiConfig.pusherAuthEndpoint;

  /// Initialiser le service Pusher
  Future<void> initialize({required String userId, String? token}) async {
    if (_isInitialized) {
      if (kDebugMode) debugPrint('⚠️ RealtimeService déjà initialisé');
      return;
    }

    _currentUserId = userId;
    _authToken = token;

    if (kDebugMode) {
      if (kDebugMode)
        debugPrint('==============================================');
      if (kDebugMode) debugPrint('🚀 INITIALISATION PUSHER');
      if (kDebugMode)
        debugPrint('==============================================');
      if (kDebugMode) debugPrint('User ID: $_currentUserId');
      if (kDebugMode) debugPrint('Pusher Key: $pusherKey');
      if (kDebugMode) debugPrint('Cluster: $pusherCluster');
      if (kDebugMode) debugPrint('Auth Endpoint: $authEndpoint');
      if (kDebugMode)
        debugPrint('==============================================');
    }

    try {
      _pusher = PusherChannelsFlutter.getInstance();

      await _pusher!.init(
        apiKey: pusherKey,
        cluster: pusherCluster,

        onError: (String message, int? code, dynamic e) {
          if (kDebugMode) {
            if (kDebugMode)
              debugPrint('❌ ERREUR PUSHER: $message (code: $code)');
          }
          onConnectionError?.call(message);
        },

        onConnectionStateChange: (String currentState, String previousState) {
          if (kDebugMode) {
            if (kDebugMode)
              debugPrint('🔄 Pusher: $previousState → $currentState');
          }
          if (currentState == 'connected') {
            onConnected?.call();
          } else if (currentState == 'disconnected') {
            onDisconnected?.call();
          } else if (currentState == 'unavailable') {
            onConnectionError?.call('Connexion WebSocket indisponible');
          }
        },

        onEvent: (PusherEvent event) {
          if (kDebugMode) {
            if (kDebugMode)
              debugPrint(
                  '📨 Pusher event: ${event.eventName} [${event.channelName}]');
          }
          _handleEvent(event);
          if (kDebugMode) debugPrint('');
        },

        onSubscriptionSucceeded: (String channelName, dynamic data) {
          _subscribedChannels.add(channelName);
          if (kDebugMode) debugPrint('✅ Pusher subscribed: $channelName');
        },

        onSubscriptionError: (String message, dynamic e) {
          if (kDebugMode) debugPrint('❌ Pusher subscription error: $message');
        },

        onDecryptionFailure: (String event, String reason) {
          if (kDebugMode) debugPrint('❌ Pusher decrypt failure: $event');
        },

        onMemberAdded: (String channelName, PusherMember member) {
          if (kDebugMode) debugPrint('👤 Member added: ${channelName}');
        },

        onMemberRemoved: (String channelName, PusherMember member) {
          if (kDebugMode) debugPrint('👤 Member removed: ${channelName}');
        },

        // Configuration pour les canaux privés
        onAuthorizer: (channelName, socketId, options) async {
          return await _authorize(channelName, socketId);
        },
      );

      await _pusher!.connect();
      _isInitialized = true;
      if (kDebugMode) debugPrint('✅ RealtimeService initialisé avec succès');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Pusher init failed: $e');
      onConnectionError?.call(e.toString());
      rethrow;
    }
  }

  /// S'authentifier auprès de Laravel pour les canaux privés
  Future<Map<String, dynamic>> _authorize(
      String channelName, String socketId) async {
    try {
      if (kDebugMode) debugPrint('');
      if (kDebugMode) debugPrint('🔐 AUTHENTIFICATION PUSHER');
      if (kDebugMode)
        debugPrint('==============================================');
      if (kDebugMode) debugPrint('Canal: $channelName');
      if (kDebugMode) debugPrint('Socket ID: $socketId');

      // Récupérer le token d'authentification
      if (_authToken == null) {
        final prefs = await SharedPreferences.getInstance();
        _authToken = prefs.getString('auth_token');
      }

      if (_authToken == null) {
        if (kDebugMode) debugPrint('❌ Token d\'authentification manquant');
        throw Exception('Token d\'authentification manquant');
      }

      if (kDebugMode) debugPrint('Token: ${_authToken!.substring(0, 20)}...');

      final requestBody = {
        'socket_id': socketId,
        'channel_name': channelName,
      };

      if (kDebugMode) debugPrint('Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(authEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) debugPrint('');
      if (kDebugMode) debugPrint('📡 RÉPONSE AUTHENTIFICATION');
      if (kDebugMode) debugPrint('   Status: ${response.statusCode}');
      if (kDebugMode) debugPrint('   Headers: ${response.headers}');
      if (kDebugMode) debugPrint('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode)
          debugPrint('✅ Authentification réussie pour $channelName');
        if (kDebugMode)
          debugPrint('   Auth: ${data['auth']?.substring(0, 30) ?? 'N/A'}...');
        if (kDebugMode)
          debugPrint('==============================================');
        if (kDebugMode) debugPrint('');
        return data;
      } else {
        if (kDebugMode) debugPrint('❌ ÉCHEC AUTHENTIFICATION');
        if (kDebugMode) debugPrint('   Code: ${response.statusCode}');
        if (kDebugMode) debugPrint('   Réponse: ${response.body}');
        if (kDebugMode)
          debugPrint('==============================================');
        throw Exception('Échec de l\'authentification: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ERREUR AUTHENTIFICATION: $e');
      if (kDebugMode)
        debugPrint('==============================================');
      rethrow;
    }
  }

  /// S'abonner au canal des commandes d'un utilisateur (canal privé)
  Future<void> subscribeToUserOrders(String userId) async {
    if (!_isInitialized || _pusher == null) {
      if (kDebugMode) debugPrint('❌ RealtimeService non initialisé');
      return;
    }

    try {
      final channelName = 'private-user.$userId.orders';
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) => _handleEvent(event),
      );
      if (kDebugMode) debugPrint('✅ Pusher subscribed: $channelName');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Pusher subscribe user orders: $e');
    }
  }

  /// S'abonner au canal d'une commande spécifique (canal public)
  /// Le backend broadcast `order.updated` sur `order.{orderId}` à chaque changement de statut.
  Future<void> subscribeToOrder(int orderId) async {
    if (!_isInitialized || _pusher == null) {
      if (kDebugMode) debugPrint('❌ RealtimeService non initialisé');
      return;
    }

    try {
      final channelName = 'order.$orderId';
      if (_subscribedChannels.contains(channelName)) return;
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) => _handleEvent(event),
      );
      if (kDebugMode) debugPrint('✅ Pusher subscribed: $channelName');
    } catch (e) {
      if (kDebugMode)
        debugPrint('❌ Pusher subscribe error (order.$orderId): $e');
    }
  }

  /// Se désabonner du canal d'une commande
  Future<void> unsubscribeFromOrder(int orderId) async {
    final channelName = 'order.$orderId';
    await unsubscribe(channelName);
  }

  /// S'abonner aux canaux de toutes les commandes actives
  Future<void> subscribeToActiveOrders(List<int> orderIds) async {
    for (final orderId in orderIds) {
      await subscribeToOrder(orderId);
    }
  }

  /// S'abonner au canal de notifications d'un utilisateur (canal privé)
  Future<void> subscribeToUserNotifications(String userId) async {
    if (!_isInitialized || _pusher == null) {
      if (kDebugMode) debugPrint('❌ RealtimeService non initialisé');
      return;
    }

    try {
      final channelName = 'private-user.$userId.notifications';
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) => _handleEvent(event),
      );
      if (kDebugMode) debugPrint('✅ Pusher subscribed: $channelName');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Pusher subscribe error (notifs): $e');
    }
  }

  /// S'abonner au canal public des notifications générales
  Future<void> subscribeToPublicNotifications() async {
    if (!_isInitialized || _pusher == null) {
      if (kDebugMode) debugPrint('❌ RealtimeService non initialisé');
      return;
    }

    try {
      const channelName = 'notifications';
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) => _handleEvent(event),
      );
      if (kDebugMode) debugPrint('✅ Pusher subscribed: $channelName');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Pusher subscribe error (public): $e');
    }
  }

  /// Gérer les événements reçus
  void _handleEvent(PusherEvent event) {
    try {
      if (kDebugMode) debugPrint('');
      if (kDebugMode) debugPrint('🔍 TRAITEMENT ÉVÉNEMENT');
      if (kDebugMode)
        debugPrint('==============================================');
      if (kDebugMode) debugPrint('Canal: ${event.channelName}');
      if (kDebugMode) debugPrint('Événement: ${event.eventName}');
      if (kDebugMode) debugPrint('Données brutes: ${event.data}');

      // Parser les données JSON
      final Map<String, dynamic> data = jsonDecode(event.data);
      if (kDebugMode) debugPrint('Données parsées: $data');

      // Nettoyer le nom de l'événement
      String eventName = event.eventName;
      eventName = eventName.replaceAll(RegExp(r'^\.?App\\Events\\'), '');
      eventName = eventName.replaceAll('\\', '.');

      if (kDebugMode) debugPrint('Nom événement nettoyé: $eventName');

      // Détecter le type d'événement
      final isOrderEvent = eventName.toLowerCase().contains('order') ||
          data.containsKey('order_id') ||
          data.containsKey('orderId') ||
          data.containsKey('order');

      final isNotificationEvent =
          eventName.toLowerCase().contains('notification') ||
              data.containsKey('notification') ||
              (data.containsKey('title') && data.containsKey('body'));

      if (kDebugMode) debugPrint('Type détecté:');
      if (kDebugMode) debugPrint('   Order: $isOrderEvent');
      if (kDebugMode) debugPrint('   Notification: $isNotificationEvent');

      // Router l'événement
      if (isOrderEvent) {
        if (kDebugMode) debugPrint('➡️ Routage vers _handleOrderEvent');
        _handleOrderEvent(eventName, data);
      } else if (isNotificationEvent) {
        if (kDebugMode) debugPrint('➡️ Routage vers _handleNotificationEvent');
        _handleNotificationEvent(eventName, data);
      } else {
        if (kDebugMode) debugPrint('⚠️ Événement non catégorisé: $eventName');
        if (data.isNotEmpty) {
          onNewNotification?.call(data);
        }
      }
      if (kDebugMode)
        debugPrint('==============================================');
      if (kDebugMode) debugPrint('');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ ERREUR TRAITEMENT ÉVÉNEMENT');
      if (kDebugMode) debugPrint('   Exception: $e');
      if (kDebugMode) debugPrint('   Event name: ${event.eventName}');
      if (kDebugMode) debugPrint('   Event data: ${event.data}');
      if (kDebugMode) debugPrint('');
    }
  }

  /// Gérer les événements de commande
  void _handleOrderEvent(String eventName, Map<String, dynamic> data) {
    final enrichedData = {
      ...data,
      'event_type': eventName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    onOrderStatusUpdate?.call(enrichedData);
  }

  /// Gérer les événements de notification
  void _handleNotificationEvent(String eventName, Map<String, dynamic> data) {
    Map<String, dynamic> notificationData;
    if (data.containsKey('notification')) {
      notificationData = Map<String, dynamic>.from(data['notification']);
      notificationData['additional_data'] = data;
    } else {
      notificationData = data;
    }
    notificationData['event_type'] = eventName;
    notificationData['timestamp'] =
        notificationData['timestamp'] ?? DateTime.now().toIso8601String();
    onNewNotification?.call(notificationData);
  }

  Future<void> unsubscribe(String channelName) async {
    if (_pusher != null) {
      try {
        await _pusher!.unsubscribe(channelName: channelName);
        _subscribedChannels.remove(channelName);
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Pusher unsubscribe error: $e');
      }
    }
  }

  Future<void> disconnect() async {
    if (_pusher != null) {
      try {
        await _pusher!.disconnect();
        _isInitialized = false;
        _currentUserId = null;
        _subscribedChannels.clear();
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Pusher disconnect error: $e');
      }
    }
  }

  void clearCallbacks() {
    onOrderStatusUpdate = null;
    onNewNotification = null;
    onConnectionError = null;
    onConnected = null;
    onDisconnected = null;
  }

  bool get isConnected => _isInitialized && _pusher != null;
  String? get currentUserId => _currentUserId;
  Set<String> get subscribedChannels => Set.unmodifiable(_subscribedChannels);

  /// Méthode de debug
  void printDebugInfo() {
    if (!kDebugMode) return;
    debugPrint(
        '📊 Pusher — init: $_isInitialized, channels: ${_subscribedChannels.length}');
    for (var channel in _subscribedChannels) {
      debugPrint('   - $channel');
    }
  }
}
