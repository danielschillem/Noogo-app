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
      debugPrint('⚠️ RealtimeService déjà initialisé');
      return;
    }

    _currentUserId = userId;
    _authToken = token;

    debugPrint('==============================================');
    debugPrint('🚀 INITIALISATION PUSHER');
    debugPrint('==============================================');
    debugPrint('User ID: $_currentUserId');
    debugPrint('Token présent: ${_authToken != null}');
    debugPrint('Pusher Key: $pusherKey');
    debugPrint('Cluster: $pusherCluster');
    debugPrint('Auth Endpoint: $authEndpoint');
    debugPrint('==============================================');

    try {
      _pusher = PusherChannelsFlutter.getInstance();

      await _pusher!.init(
        apiKey: pusherKey,
        cluster: pusherCluster,

        onError: (String message, int? code, dynamic e) {
          debugPrint('❌ ERREUR PUSHER');
          debugPrint('   Message: $message');
          debugPrint('   Code: $code');
          debugPrint('   Exception: $e');
          onConnectionError?.call(message);
        },

        onConnectionStateChange: (String currentState, String previousState) {
          debugPrint('');
          debugPrint('🔄 CHANGEMENT ÉTAT PUSHER');
          debugPrint('   De: $previousState');
          debugPrint('   Vers: $currentState');
          debugPrint('   Timestamp: ${DateTime.now().toIso8601String()}');

          if (currentState == 'connected') {
            debugPrint('✅ CONNEXION WEBSOCKET ÉTABLIE');
            onConnected?.call();
          } else if (currentState == 'disconnected') {
            debugPrint('⚠️ CONNEXION WEBSOCKET FERMÉE');
            onDisconnected?.call();
          } else if (currentState == 'connecting') {
            debugPrint('🔄 CONNEXION EN COURS...');
          } else if (currentState == 'unavailable') {
            debugPrint('❌ CONNEXION INDISPONIBLE');
            onConnectionError?.call('Connexion WebSocket indisponible');
          }
          debugPrint('');
        },

        onEvent: (PusherEvent event) {
          debugPrint('');
          debugPrint('📨 ÉVÉNEMENT PUSHER REÇU');
          debugPrint('   Canal: ${event.channelName}');
          debugPrint('   Événement: ${event.eventName}');
          debugPrint('   Données brutes: ${event.data}');
          debugPrint('   User ID: ${event.userId}');
          debugPrint('   Timestamp: ${DateTime.now().toIso8601String()}');
          _handleEvent(event);
          debugPrint('');
        },

        onSubscriptionSucceeded: (String channelName, dynamic data) {
          debugPrint('');
          debugPrint('✅ SOUSCRIPTION RÉUSSIE');
          debugPrint('   Canal: $channelName');
          debugPrint('   Data: $data');
          _subscribedChannels.add(channelName);
          debugPrint('   Total canaux souscrits: ${_subscribedChannels.length}');
          debugPrint('   Liste: $_subscribedChannels');
          debugPrint('');
        },

        onSubscriptionError: (String message, dynamic e) {
          debugPrint('');
          debugPrint('❌ ERREUR SOUSCRIPTION');
          debugPrint('   Message: $message');
          debugPrint('   Exception: $e');
          debugPrint('');
        },

        onDecryptionFailure: (String event, String reason) {
          debugPrint('❌ Échec décryptage: $event - $reason');
        },

        onMemberAdded: (String channelName, PusherMember member) {
          debugPrint('👤 Membre ajouté à $channelName: ${member.userId}');
        },

        onMemberRemoved: (String channelName, PusherMember member) {
          debugPrint('👤 Membre retiré de $channelName: ${member.userId}');
        },

        // Configuration pour les canaux privés
        onAuthorizer: (channelName, socketId, options) async {
          debugPrint('');
          debugPrint('🔐 DEMANDE AUTORISATION');
          debugPrint('   Canal: $channelName');
          debugPrint('   Socket ID: $socketId');
          return await _authorize(channelName, socketId);
        },
      );

      debugPrint('🔌 Tentative de connexion à Pusher...');
      await _pusher!.connect();

      _isInitialized = true;
      debugPrint('✅ RealtimeService initialisé avec succès');

    } catch (e) {
      debugPrint('❌ ERREUR FATALE lors de l\'initialisation de Pusher: $e');
      onConnectionError?.call(e.toString());
      rethrow;
    }
  }

  /// S'authentifier auprès de Laravel pour les canaux privés
  Future<Map<String, dynamic>> _authorize(String channelName, String socketId) async {
    try {
      debugPrint('');
      debugPrint('🔐 AUTHENTIFICATION PUSHER');
      debugPrint('==============================================');
      debugPrint('Canal: $channelName');
      debugPrint('Socket ID: $socketId');

      // Récupérer le token d'authentification
      if (_authToken == null) {
        final prefs = await SharedPreferences.getInstance();
        _authToken = prefs.getString('auth_token');
      }

      if (_authToken == null) {
        debugPrint('❌ Token d\'authentification manquant');
        throw Exception('Token d\'authentification manquant');
      }

      debugPrint('Token: ${_authToken!.substring(0, 20)}...');

      final requestBody = {
        'socket_id': socketId,
        'channel_name': channelName,
      };

      debugPrint('Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(authEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('');
      debugPrint('📡 RÉPONSE AUTHENTIFICATION');
      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Headers: ${response.headers}');
      debugPrint('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Authentification réussie pour $channelName');
        debugPrint('   Auth: ${data['auth']?.substring(0, 30) ?? 'N/A'}...');
        debugPrint('==============================================');
        debugPrint('');
        return data;
      } else {
        debugPrint('❌ ÉCHEC AUTHENTIFICATION');
        debugPrint('   Code: ${response.statusCode}');
        debugPrint('   Réponse: ${response.body}');
        debugPrint('==============================================');
        throw Exception('Échec de l\'authentification: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ ERREUR AUTHENTIFICATION: $e');
      debugPrint('==============================================');
      rethrow;
    }
  }

  /// S'abonner au canal des commandes d'un utilisateur (canal privé)
  Future<void> subscribeToUserOrders(String userId) async {
    if (!_isInitialized || _pusher == null) {
      debugPrint('❌ RealtimeService non initialisé');
      return;
    }

    try {
      // Canal privé pour les commandes de l'utilisateur
      final channelName = 'private-user.$userId.orders';

      debugPrint('');
      debugPrint('📢 SOUSCRIPTION AU CANAL COMMANDES');
      debugPrint('==============================================');
      debugPrint('Canal: $channelName');
      debugPrint('User ID: $userId');

      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) {
          debugPrint('📦 Événement commande reçu direct: ${event.eventName}');
          _handleEvent(event);
        },
      );

      debugPrint('✅ Abonné au canal: $channelName');
      debugPrint('==============================================');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Erreur d\'abonnement au canal commandes: $e');
      rethrow;
    }
  }

  /// S'abonner au canal de notifications d'un utilisateur (canal privé)
  Future<void> subscribeToUserNotifications(String userId) async {
    if (!_isInitialized || _pusher == null) {
      debugPrint('❌ RealtimeService non initialisé');
      return;
    }

    try {
      final channelName = 'private-user.$userId.notifications';

      debugPrint('');
      debugPrint('📢 SOUSCRIPTION AU CANAL NOTIFICATIONS');
      debugPrint('==============================================');
      debugPrint('Canal: $channelName');

      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) {
          debugPrint('🔔 Événement notification reçu direct: ${event.eventName}');
          _handleEvent(event);
        },
      );

      debugPrint('✅ Abonné au canal: $channelName');
      debugPrint('==============================================');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Erreur d\'abonnement aux notifications: $e');
    }
  }

  /// S'abonner au canal public des notifications générales
  Future<void> subscribeToPublicNotifications() async {
    if (!_isInitialized || _pusher == null) {
      debugPrint('❌ RealtimeService non initialisé');
      return;
    }

    try {
      const channelName = 'notifications';

      debugPrint('');
      debugPrint('📢 SOUSCRIPTION AU CANAL PUBLIC');
      debugPrint('==============================================');
      debugPrint('Canal: $channelName');

      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) {
          debugPrint('🔔 Événement notification publique reçu: ${event.eventName}');
          _handleEvent(event);
        },
      );

      debugPrint('✅ Abonné au canal public: $channelName');
      debugPrint('==============================================');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Erreur d\'abonnement aux notifications publiques: $e');
    }
  }

  /// Gérer les événements reçus
  void _handleEvent(PusherEvent event) {
    try {
      debugPrint('');
      debugPrint('🔍 TRAITEMENT ÉVÉNEMENT');
      debugPrint('==============================================');
      debugPrint('Canal: ${event.channelName}');
      debugPrint('Événement: ${event.eventName}');
      debugPrint('Données brutes: ${event.data}');

      // Parser les données JSON
      final Map<String, dynamic> data = jsonDecode(event.data);
      debugPrint('Données parsées: $data');

      // Nettoyer le nom de l'événement
      String eventName = event.eventName;
      eventName = eventName.replaceAll(RegExp(r'^\.?App\\Events\\'), '');
      eventName = eventName.replaceAll('\\', '.');

      debugPrint('Nom événement nettoyé: $eventName');

      // Détecter le type d'événement
      final isOrderEvent = eventName.toLowerCase().contains('order') ||
          data.containsKey('order_id') ||
          data.containsKey('orderId') ||
          data.containsKey('order');

      final isNotificationEvent = eventName.toLowerCase().contains('notification') ||
          data.containsKey('notification') ||
          (data.containsKey('title') && data.containsKey('body'));

      debugPrint('Type détecté:');
      debugPrint('   Order: $isOrderEvent');
      debugPrint('   Notification: $isNotificationEvent');

      // Router l'événement
      if (isOrderEvent) {
        debugPrint('➡️ Routage vers _handleOrderEvent');
        _handleOrderEvent(eventName, data);
      } else if (isNotificationEvent) {
        debugPrint('➡️ Routage vers _handleNotificationEvent');
        _handleNotificationEvent(eventName, data);
      } else {
        debugPrint('⚠️ Événement non catégorisé: $eventName');
        if (data.isNotEmpty) {
          onNewNotification?.call(data);
        }
      }
      debugPrint('==============================================');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ ERREUR TRAITEMENT ÉVÉNEMENT');
      debugPrint('   Exception: $e');
      debugPrint('   Event name: ${event.eventName}');
      debugPrint('   Event data: ${event.data}');
      debugPrint('');
    }
  }

  /// Gérer les événements de commande
  void _handleOrderEvent(String eventName, Map<String, dynamic> data) {
    debugPrint('📦 TRAITEMENT ÉVÉNEMENT COMMANDE');
    debugPrint('==============================================');

    final orderId = data['order_id'] ?? data['orderId'] ?? data['id'];
    final status = data['status'] ?? data['order_status'];

    debugPrint('Order ID: $orderId');
    debugPrint('Status: $status');

    // Enrichir les données
    final enrichedData = {
      ...data,
      'event_type': eventName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    debugPrint('Appel callback onOrderStatusUpdate...');
    onOrderStatusUpdate?.call(enrichedData);
    debugPrint('✅ Callback appelé');
    debugPrint('==============================================');
    debugPrint('');
  }

  /// Gérer les événements de notification
  void _handleNotificationEvent(String eventName, Map<String, dynamic> data) {
    debugPrint('🔔 TRAITEMENT ÉVÉNEMENT NOTIFICATION');
    debugPrint('==============================================');

    Map<String, dynamic> notificationData;

    if (data.containsKey('notification')) {
      notificationData = Map<String, dynamic>.from(data['notification']);
      notificationData['additional_data'] = data;
    } else {
      notificationData = data;
    }

    notificationData['event_type'] = eventName;
    notificationData['timestamp'] = notificationData['timestamp'] ??
        DateTime.now().toIso8601String();

    debugPrint('Données notification: $notificationData');
    debugPrint('Appel callback onNewNotification...');
    onNewNotification?.call(notificationData);
    debugPrint('✅ Callback appelé');
    debugPrint('==============================================');
    debugPrint('');
  }

  Future<void> unsubscribe(String channelName) async {
    if (_pusher != null) {
      try {
        await _pusher!.unsubscribe(channelName: channelName);
        _subscribedChannels.remove(channelName);
        debugPrint('✅ Désabonné du canal: $channelName');
      } catch (e) {
        debugPrint('❌ Erreur de désabonnement: $e');
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
        debugPrint('✅ Déconnexion Pusher réussie');
      } catch (e) {
        debugPrint('❌ Erreur de déconnexion: $e');
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
    debugPrint('');
    debugPrint('==============================================');
    debugPrint('📊 DEBUG INFO PUSHER');
    debugPrint('==============================================');
    debugPrint('Initialisé: $_isInitialized');
    debugPrint('User ID: $_currentUserId');
    debugPrint('Token présent: ${_authToken != null}');
    debugPrint('Canaux souscrits: ${_subscribedChannels.length}');
    for (var channel in _subscribedChannels) {
      debugPrint('   - $channel');
    }
    debugPrint('Callbacks configurés:');
    debugPrint('   - onOrderStatusUpdate: ${onOrderStatusUpdate != null}');
    debugPrint('   - onNewNotification: ${onNewNotification != null}');
    debugPrint('   - onConnected: ${onConnected != null}');
    debugPrint('   - onDisconnected: ${onDisconnected != null}');
    debugPrint('   - onConnectionError: ${onConnectionError != null}');
    debugPrint('==============================================');
    debugPrint('');
  }
}