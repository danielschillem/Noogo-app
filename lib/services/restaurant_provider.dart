import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import '../models/dish.dart';
import '../models/flash_info.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/app_notification.dart';
import '../config/api_config.dart';
import '../config/demo_data.dart';
import '../utils/qr_helper.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'realtime_service.dart';
import 'analytics_service.dart';
import 'favorites_service.dart';
import 'fcm_service.dart';

/// Machine d'état pour la soumission de commandes
enum OrderSubmitState { idle, submitting, success, error }

class RestaurantProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final RealtimeService _realtimeService = RealtimeService();

  static const String _ordersKey = 'local_orders';
  static const String _menuCacheKey = 'offline_menu_cache';
  static const int _maxStoredOrders = 50;

  // NOUVEAU: Timer et tracking des statuts
  Timer? _autoRefreshTimer;
  final Map<int, OrderStatus> _lastOrderStatuses = {};

  // --- États généraux ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasApiError = false;
  bool get hasApiError => _hasApiError;

  String? _error;
  String? get error => _error;

  bool _isLoadingOrders = false;
  bool get isLoadingOrders => _isLoadingOrders;

  // --- Machine d'état pour la soumission de commande ---
  OrderSubmitState _orderSubmitState = OrderSubmitState.idle;
  OrderSubmitState get orderSubmitState => _orderSubmitState;
  bool get isSubmittingOrder =>
      _orderSubmitState == OrderSubmitState.submitting;
  String? _orderSubmitError;
  String? get orderSubmitError => _orderSubmitError;

  bool _isRealtimeConnected = false;
  bool get isRealtimeConnected => _isRealtimeConnected;

  // --- Données principales ---
  Restaurant? _restaurant;
  Restaurant? get restaurant => _restaurant;

  List<Dish> _dishes = [];
  List<Dish> get dishes => _dishes;

  List<Dish> _dishesOfTheDay = [];
  List<Dish> get dishesOfTheDay => _dishesOfTheDay;

  List<FlashInfo> _flashInfos = [];
  List<FlashInfo> get flashInfos => _flashInfos;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  List<Order> _orders = [];
  List<Order> get orders => _orders;

  // --- Favoris ---
  Set<int> _favoriteDishIds = {};
  Set<int> get favoriteDishIds => Set.unmodifiable(_favoriteDishIds);
  bool isFavoriteDish(int dishId) => _favoriteDishIds.contains(dishId);
  List<Dish> get favoriteDishes =>
      _dishes.where((d) => _favoriteDishIds.contains(d.id)).toList();

  // --- Hors-ligne ---
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  // --- Notifications ---
  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  // --- État de validation du QR Code ---
  String? _scannedQRCode;
  String? get scannedQRCode => _scannedQRCode;

  // --- Panier ---
  final List<OrderItem> _cartItems = [];
  List<OrderItem> get cartItems => List.unmodifiable(_cartItems);

  double get cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  int get cartItemsCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);
  bool get hasCartItems => _cartItems.isNotEmpty;

  // --- Navigation ---
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // ===================================================================
  //  SECTION AUTO-REFRESH AUTOMATIQUE DES COMMANDES
  // ===================================================================

  /// Démarrer le rafraîchissement automatique des commandes
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30), // Toutes les 30 secondes
      (timer) async {
        if (kDebugMode) debugPrint('🔄 Auto-refresh des commandes...');
        await _autoLoadOrdersWithNotifications();
      },
    );

    if (kDebugMode) {
      debugPrint('✅ Auto-refresh activé (toutes les 30 secondes)');
    }
  }

  /// Charger les commandes ET créer des notifications pour les changements
  Future<void> _autoLoadOrdersWithNotifications() async {
    try {
      if (_restaurant == null) return;

      final fetchedOrders =
          await _apiService.getOrders(restaurantId: _restaurant!.id);

      if (fetchedOrders.isEmpty) return;

      for (var newOrder in fetchedOrders) {
        final orderId = newOrder.id;
        final newStatus = newOrder.status;
        final oldStatus = _lastOrderStatuses[orderId];

        if (oldStatus != null && oldStatus != newStatus) {
          if (kDebugMode) {
            debugPrint(
                '📢 Changement: commande #$orderId: $oldStatus → $newStatus');
          }
          await _createNotificationForStatusChange(
              newOrder, oldStatus, newStatus);
        }

        _lastOrderStatuses[orderId] = newStatus;
      }

      _orders = fetchedOrders
        ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

      await _saveOrdersLocally(_orders);

      if (kDebugMode) {
        debugPrint('✅ ${fetchedOrders.length} commandes mises à jour');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur auto-refresh: $e');
    }
  }

  /// Créer une notification pour un changement de statut
  Future<void> _createNotificationForStatusChange(
    Order order,
    OrderStatus oldStatus,
    OrderStatus newStatus,
  ) async {
    try {
      String title = '';
      String body = '';
      String emoji = '';

      switch (newStatus) {
        case OrderStatus.confirmed:
          emoji = '✅';
          title = 'Commande confirmée';
          body = 'Votre commande #${order.id} a été confirmée.';
          break;
        case OrderStatus.preparing:
          emoji = '👨‍🍳';
          title = 'En préparation';
          body = 'Votre commande #${order.id} est en cours de préparation.';
          break;
        case OrderStatus.ready:
          emoji = '🎉';
          title = 'Commande prête !';
          body = 'Votre commande #${order.id} est prête à être récupérée.';
          break;
        case OrderStatus.delivered:
          emoji = '🚚';
          title = 'Commande livrée';
          body = 'Votre commande #${order.id} a été livrée. Bon appétit !';
          break;
        case OrderStatus.completed:
          emoji = '✔️';
          title = 'Commande terminée';
          body = 'Merci pour votre commande #${order.id} !';
          break;
        case OrderStatus.cancelled:
          emoji = '❌';
          title = 'Commande annulée';
          body = 'Votre commande #${order.id} a été annulée.';
          break;
        default:
          emoji = 'ℹ️';
          title = 'Mise à jour';
          body = 'Statut de la commande #${order.id} mis à jour.';
      }

      final notification = AppNotification(
        id: 'auto_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: '$emoji $title',
        body: body,
        timestamp: DateTime.now(),
        type: 'order',
        isRead: false,
        data: {
          'orderId': order.id.toString(),
          'oldStatus': oldStatus.toString(),
          'newStatus': newStatus.toString(),
        },
      );

      await addNotification(notification);
      if (kDebugMode) debugPrint('✅ Notification créée: $title');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur création notification: $e');
    }
  }

  /// Forcer un rafraîchissement manuel
  Future<void> forceRefreshOrders() async {
    if (kDebugMode) debugPrint('🔄 Rafraîchissement manuel...');
    await _autoLoadOrdersWithNotifications();
  }

  // ===================================================================
  // SECTION NOTIFICATIONS
  // ===================================================================

  Future<void> loadNotifications() async {
    try {
      _notifications = await NotificationService.loadNotifications();
      if (kDebugMode) {
        debugPrint('✅ Notifications chargées: ${_notifications.length}');
      }

      // ✅ AJOUTEZ CE TRY-CATCH
      try {
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Widget détruit lors de la notification: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur chargement notifications: $e');
      _notifications = [];
    }
  }

  Future<void> addNotification(AppNotification notification) async {
    try {
      await NotificationService.addNotification(notification);
      await loadNotifications();
      if (kDebugMode) {
        debugPrint('✅ Notification ajoutée: ${notification.title}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur ajout notification: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
      await loadNotifications();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur mise à jour notification: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      await loadNotifications();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur mise à jour notifications: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);
      await loadNotifications();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur suppression notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await NotificationService.clearAllNotifications();
      await loadNotifications();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur suppression notifications: $e');
    }
  }

  Future<void> createTestNotification(String type) async {
    try {
      final notification = NotificationService.createTestNotification(type);
      await addNotification(notification);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur création notification test: $e');
    }
  }

  Future<void> createOrderNotification(Order order) async {
    try {
      final notification = AppNotification(
        id: 'notif_order_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: '✅ Commande confirmée',
        body:
            'Votre commande #${order.id} a été confirmée. Total: ${order.totalPrice.toStringAsFixed(0)} FCFA',
        timestamp: DateTime.now(),
        type: 'order',
        isRead: false,
        data: {
          'orderId': order.id.toString(),
          'status': order.status.toString(),
          'total': order.totalPrice,
        },
      );
      await addNotification(notification);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Erreur création notification commande: $e');
      }
    }
  }

  // ===================================================================
  // ✅ SECTION PUSHER - TEMPS RÉEL
  // ===================================================================

  /// Initialiser le provider avec Pusher
  Future<void> initialize({String? userId, String? authToken}) async {
    await loadNotifications();

    // Initialiser Pusher si l'utilisateur est connecté
    if (userId != null && userId.isNotEmpty) {
      await _initializePusher(userId, authToken);
    }

    // Démarrer l'auto-refresh
    _startAutoRefresh();
  }

  /// ✅ Initialiser Pusher avec les nouveaux credentials
  Future<void> _initializePusher(String userId, String? authToken) async {
    try {
      if (kDebugMode) debugPrint('🔌 Initialisation de Pusher...');

      // Configurer les callbacks
      _realtimeService.onConnected = () {
        if (kDebugMode) debugPrint('✅ Pusher connecté');
        _isRealtimeConnected = true;
        notifyListeners();
      };

      _realtimeService.onDisconnected = () {
        if (kDebugMode) debugPrint('⚠️ Pusher déconnecté');
        _isRealtimeConnected = false;
        notifyListeners();
      };

      _realtimeService.onConnectionError = (error) {
        if (kDebugMode) debugPrint('❌ Erreur Pusher: $error');
        _isRealtimeConnected = false;
        notifyListeners();
      };

      // ✅ Callback pour les mises à jour de commandes
      _realtimeService.onOrderStatusUpdate = (data) async {
        if (kDebugMode) {
          debugPrint('📦 Mise à jour commande reçue via Pusher: $data');
        }
        await _handleOrderStatusUpdate(data);
      };

      // ✅ Callback pour les nouvelles notifications
      _realtimeService.onNewNotification = (data) async {
        if (kDebugMode) {
          debugPrint('🔔 Nouvelle notification reçue via Pusher: $data');
        }
        await _handleNewNotification(data);
      };

      // Initialiser Pusher
      await _realtimeService.initialize(userId: userId, token: authToken);

      // S'abonner aux canaux
      await _realtimeService.subscribeToUserOrders(userId);
      await _realtimeService.subscribeToUserNotifications(userId);
      await _realtimeService.subscribeToPublicNotifications();

      if (kDebugMode) debugPrint('✅ Pusher initialisé et canaux souscrits');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur initialisation Pusher: $e');
      _isRealtimeConnected = false;
      notifyListeners();
    }
  }

  /// ✅ Gérer les mises à jour de commande depuis Pusher
  Future<void> _handleOrderStatusUpdate(Map<String, dynamic> data) async {
    try {
      if (kDebugMode) debugPrint('📦 Traitement mise à jour commande: $data');

      final orderId = data['order_id'] ?? data['orderId'] ?? data['id'];
      final newStatusStr = data['status'] ?? data['order_status'];

      if (orderId == null) {
        if (kDebugMode) debugPrint('⚠️ order_id manquant dans les données');
        return;
      }

      // Trouver la commande dans la liste locale
      final orderIndex =
          _orders.indexWhere((o) => o.id.toString() == orderId.toString());

      if (orderIndex != -1) {
        final oldOrder = _orders[orderIndex];
        final oldStatus = oldOrder.status;
        final newStatus = _mapStringToOrderStatus(newStatusStr);

        if (newStatus != null && oldStatus != newStatus) {
          if (kDebugMode) {
            debugPrint(
                '✅ Mise à jour: commande #$orderId: $oldStatus → $newStatus');
          }

          // Mettre à jour la commande
          _orders[orderIndex] = oldOrder.copyWith(status: newStatus);
          _lastOrderStatuses[oldOrder.id] = newStatus;

          // Créer une notification
          await _createNotificationForStatusChange(
            _orders[orderIndex],
            oldStatus,
            newStatus,
          );

          notifyListeners();
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '⚠️ Commande #$orderId non trouvée localement, rechargement...');
        }
        await loadOrders();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur traitement mise à jour commande: $e');
      }
    }
  }

  /// ✅ Gérer les nouvelles notifications depuis Pusher
  Future<void> _handleNewNotification(Map<String, dynamic> data) async {
    try {
      if (kDebugMode) debugPrint('🔔 Traitement nouvelle notification: $data');

      final notification = AppNotification(
        id: data['id']?.toString() ??
            'notif_pusher_${DateTime.now().millisecondsSinceEpoch}',
        title: data['title'] ?? 'Notification',
        body: data['body'] ?? data['message'] ?? '',
        timestamp: data['timestamp'] != null
            ? DateTime.parse(data['timestamp'])
            : DateTime.now(),
        type: data['type'] ?? 'info',
        isRead: false,
        data: data['data'] ?? {},
      );

      await addNotification(notification);
      if (kDebugMode) {
        debugPrint('✅ Notification Pusher ajoutée: ${notification.title}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur traitement notification Pusher: $e');
    }
  }

  /// Mapper un string en OrderStatus
  OrderStatus? _mapStringToOrderStatus(String? status) {
    if (status == null) return null;

    final statusLower = status.toLowerCase().trim();

    switch (statusLower) {
      case 'pending':
      case 'en attente':
        return OrderStatus.pending;
      case 'confirmed':
      case 'confirmée':
      case 'confirmee':
        return OrderStatus.confirmed;
      case 'preparing':
      case 'en préparation':
      case 'en preparation':
        return OrderStatus.preparing;
      case 'ready':
      case 'prête':
      case 'prete':
        return OrderStatus.ready;
      case 'delivered':
      case 'livrée':
      case 'livree':
        return OrderStatus.delivered;
      case 'completed':
      case 'terminée':
      case 'terminee':
        return OrderStatus.completed;
      case 'cancelled':
      case 'annulée':
      case 'annulee':
        return OrderStatus.cancelled;
      default:
        if (kDebugMode) debugPrint('⚠️ Statut inconnu: $status');
        return null;
    }
  }

  /// Se déconnecter de Pusher
  Future<void> disposeRealtime() async {
    try {
      await _realtimeService.disconnect();
      _realtimeService.clearCallbacks();
      _isRealtimeConnected = false;
      if (kDebugMode) debugPrint('✅ Pusher déconnecté');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur déconnexion Pusher: $e');
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    unawaited(disposeRealtime());
    super.dispose();
  }

  // ===================================================================
  // RESTE DU CODE INCHANGÉ
  // ===================================================================

  Future<void> validateRestaurantQRCode(String qrData) async {
    // Éviter les validations simultanées
    if (_isLoading) {
      if (kDebugMode) debugPrint('⏳ Validation déjà en cours, ignorée');
      return;
    }

    _isLoading = true;
    _hasApiError = false;
    _clearError();
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('');
        debugPrint('🔍 === validateRestaurantQRCode ===');
        debugPrint('   QR Code: $qrData');
      }

      // 1️⃣ Validation du format
      if (!QRHelper.isValidRestaurantQR(qrData)) {
        throw Exception(
          'Ce QR Code n\'est pas valide pour notre application.\n'
          'URL attendue: ${ApiConfig.baseUrl}',
        );
      }

      // 2️⃣ Extraction de l'ID
      final int? restaurantId = QRHelper.parseRestaurantId(qrData);

      if (restaurantId == null || restaurantId <= 0) {
        throw Exception(
          'Impossible d\'extraire un ID restaurant valide depuis le QR Code.\n'
          'Format attendu: ${ApiConfig.baseUrl}/restaurant/{id}/menu',
        );
      }

      if (kDebugMode) debugPrint('✅ Restaurant ID extrait: $restaurantId');

      // 3️⃣ Réinitialiser les données SAUF Pusher
      if (kDebugMode) debugPrint('🔄 Réinitialisation des données...');
      _resetDataOnly(); // ✅ Nouvelle méthode qui ne touche pas à Pusher

      // 4️⃣ Chargement des données
      if (kDebugMode) {
        debugPrint('📡 Chargement des données du restaurant $restaurantId...');
      }

      _isLoading = false; // Reset temporaire
      await loadAllInitialData(restaurantId: restaurantId);

      // 5️⃣ Vérification finale
      if (_restaurant == null) {
        throw Exception('Impossible de charger les données du restaurant');
      }

      // 6️⃣ Sauvegarde du QR
      _scannedQRCode = qrData;

      // 7️⃣ Analytics
      unawaited(AnalyticsService.qrValidated(
        _restaurant!.id,
        _restaurant!.nom,
      ));

      // 8️⃣ Redémarrer l'auto-refresh
      _startAutoRefresh();

      if (kDebugMode) {
        debugPrint('✅ Validation complète réussie');
        debugPrint('   Restaurant: ${_restaurant!.nom}');
        debugPrint('   Plats: ${_dishes.length}');
        debugPrint('');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('');
        debugPrint('❌ === ERREUR validateRestaurantQRCode ===');
        debugPrint('   - Erreur: $e');
        debugPrint('   - Stack: $stackTrace');
        debugPrint('');
      }
      _hasApiError = true;
      _setError(e.toString());

      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Réinitialiser uniquement les données, SANS toucher à Pusher
  void _resetDataOnly() {
    if (kDebugMode) {
      debugPrint('🔄 Réinitialisation des données (Pusher conservé)...');
    }

    // Arrêter l'auto-refresh
    _autoRefreshTimer?.cancel();

    // Réinitialiser les états
    _hasApiError = false;
    _error = null;
    _isLoadingOrders = false;

    // Vider toutes les données
    _restaurant = null;
    _dishes = [];
    _dishesOfTheDay = [];
    _flashInfos = [];
    _categories = [];
    _orders = [];
    _cartItems.clear();
    _lastOrderStatuses.clear();

    // ❌ NE PAS réinitialiser :
    // - _scannedQRCode (sera mis à jour après validation)
    // - _notifications (on garde l'historique)
    // - Pusher (_realtimeService) - reste connecté
    // - _isRealtimeConnected - inchangé

    // Réinitialiser la navigation
    _currentNavIndex = 0;

    // Nettoyer le cache
    ApiConfig.clearValidationCache();

    if (kDebugMode) debugPrint('✅ Données réinitialisées (Pusher intact)');
  }

  void clearQRCode() {
    _scannedQRCode = null;
    notifyListeners();
  }

  /// Charge des données de démonstration statiques (aucun réseau requis).
  /// Appelé automatiquement en mode debug quand aucun QR code n'est disponible.
  void loadDemoData() {
    if (_isLoading) return;
    _isLoading = false;
    _hasApiError = false;
    _restaurant = DemoData.restaurant;
    _categories = DemoData.categories;
    _dishes = DemoData.dishes;
    _flashInfos = DemoData.flashInfos;
    _dishesOfTheDay = _dishes.where((d) => d.isDishOfTheDay).toList();
    _isOffline = false;
    if (kDebugMode) {
      debugPrint(
          '🎭 Demo data chargée (${_dishes.length} plats, ${_categories.length} catégories)');
    }
    notifyListeners();
  }

  Future<void> loadAllInitialData({required int restaurantId}) async {
    // Si déjà en cours de chargement, on évite les doublons
    if (_isLoading) {
      if (kDebugMode) {
        debugPrint('⏳ Chargement déjà en cours pour restaurant $restaurantId');
      }
      return;
    }

    _isLoading = true;
    _hasApiError = false;
    _clearError();
    notifyListeners(); // ✅ Notifier dès le début

    try {
      if (kDebugMode) {
        debugPrint('');
        debugPrint('📡 === DÉBUT loadAllInitialData ===');
        debugPrint('   - Restaurant ID: $restaurantId');
      }

      // Validation ID
      if (restaurantId <= 0) {
        throw Exception("L'ID du restaurant doit être un nombre positif");
      }

      // ===== MENU & RESTAURANT (BLOQUANT) =====
      if (kDebugMode) debugPrint('📡 Chargement du menu...');
      final menuData = await _apiService
          .getRestaurantMenu(
        restaurantId: restaurantId,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
              'Timeout: Impossible de charger le menu du restaurant');
        },
      );

      if (kDebugMode) {
        debugPrint('✅ Menu reçu:');
        debugPrint('   - Restaurant: ${menuData.restaurant.nom}');
        debugPrint('   - Plats: ${menuData.dishes.length}');
        debugPrint('   - Plats du jour: ${menuData.dishesOfTheDay.length}');
        debugPrint('   - Catégories: ${menuData.categories.length}');
      }

      // ✅ Assignation immédiate (CRITIQUE)
      _restaurant = menuData.restaurant;
      _dishes = menuData.dishes;
      _dishesOfTheDay = menuData.dishesOfTheDay;
      _categories = menuData.categories;
      _isOffline = false;

      if (_restaurant == null) {
        throw Exception('Restaurant introuvable pour ID: $restaurantId');
      }

      // ✅ Sauvegarder le menu en cache (FEAT-001)
      _saveMenuCache(restaurantId, menuData);

      // ✅ Charger les favoris (FEAT-004)
      _favoriteDishIds = await FavoritesService.loadFavorites();

      // ✅ Notifier immédiatement après le chargement des données principales
      _isLoading = false; // ✅ Marquer comme terminé AVANT de notifier
      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Données principales chargées - UI peut s\'afficher');
      }

      // ===== DONNÉES SECONDAIRES (NON BLOQUANTES) =====
      // On charge en arrière-plan sans bloquer l'UI

      // COMMANDES
      _loadOrdersInBackground();

      // NOTIFICATIONS
      _loadNotificationsInBackground();

      // FLASH INFOS
      _loadFlashInfosInBackground(restaurantId);

      // S'abonner au topic FCM du restaurant (pour recevoir les notifs push staff)
      FCMService.subscribeToTopic('restaurant_$restaurantId').ignore();

      if (kDebugMode) {
        debugPrint('✅ === loadAllInitialData TERMINÉ ===');
        debugPrint('   - Restaurant: ${_restaurant?.nom}');
        debugPrint('   - Plats: ${_dishes.length}');
        debugPrint('');
      }

      _hasApiError = false;
      _clearError();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('');
        debugPrint('❌ === ERREUR loadAllInitialData ===');
        debugPrint('   - Erreur: $e');
        debugPrint('   - Stack: $stackTrace');
        debugPrint('');
      }

      _setError('Erreur de connexion au restaurant');
      _hasApiError = true;

      // Tentative de chargement depuis le cache (FEAT-001)
      final cached = await _loadMenuCache(restaurantId);
      if (cached) {
        _isOffline = true;
        _favoriteDishIds = await FavoritesService.loadFavorites();
        _clearError();
        _hasApiError = false;
        if (kDebugMode) {
          debugPrint('📂 Menu chargé depuis le cache (mode hors-ligne)');
        }
      } else {
        // Réinitialisation contrôlée
        _restaurant = null;
        _dishes = [];
        _dishesOfTheDay = [];
        _categories = [];
        _flashInfos = [];
        rethrow;
      }
    } finally {
      if (_isLoading) {
        // Seulement si pas déjà fait
        _isLoading = false;
        notifyListeners();
      }
    }
  }

// ===== MÉTHODES DE CHARGEMENT EN ARRIÈRE-PLAN =====

  // ===================================================================
  // FEAT-001 — CACHE MENU HORS-LIGNE
  // ===================================================================

  void _saveMenuCache(int restaurantId, dynamic menuData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'restaurant_id': restaurantId,
        'timestamp': DateTime.now().toIso8601String(),
        'restaurant': _restaurant?.toJson(),
        'dishes': _dishes.map((d) => d.toJson()).toList(),
        'dishes_of_day': _dishesOfTheDay.map((d) => d.toJson()).toList(),
        'categories': _categories.map((c) => c.toJson()).toList(),
      });
      await prefs.setString(_menuCacheKey, data);
      if (kDebugMode) {
        debugPrint('💾 Menu mis en cache pour le restaurant $restaurantId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Impossible de mettre le menu en cache: $e');
      }
    }
  }

  Future<bool> _loadMenuCache(int restaurantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_menuCacheKey);
      if (encoded == null) return false;

      final data = jsonDecode(encoded) as Map<String, dynamic>;
      if (data['restaurant_id'] != restaurantId) return false;

      _restaurant = data['restaurant'] != null
          ? Restaurant.fromJson(data['restaurant'] as Map<String, dynamic>)
          : null;
      if (_restaurant == null) return false;

      _dishes = ((data['dishes'] as List?) ?? [])
          .map((j) => Dish.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      _dishesOfTheDay = ((data['dishes_of_day'] as List?) ?? [])
          .map((j) => Dish.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      _categories = ((data['categories'] as List?) ?? [])
          .map((j) => Category.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Impossible de charger le cache menu: $e');
      return false;
    }
  }

  // ===================================================================
  // FEAT-004 — FAVORIS
  // ===================================================================

  Future<void> toggleFavoriteDish(int dishId) async {
    _favoriteDishIds = await FavoritesService.toggleFavorite(dishId);
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    _favoriteDishIds = await FavoritesService.loadFavorites();
    notifyListeners();
  }

  // ===================================================================
  // SECTION COMMANDES (LOCAL)
  // ===================================================================

  /// Persiste les commandes en local pour survivre aux redémarrages
  Future<void> _saveOrdersLocally(List<Order> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final limited = orders.take(_maxStoredOrders).toList();
      final encoded = jsonEncode(limited.map((o) => o.toJson()).toList());
      await prefs.setString(_ordersKey, encoded);
      if (kDebugMode) {
        debugPrint('💾 ${limited.length} commandes sauvegardées localement');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Impossible de sauvegarder les commandes: $e');
      }
    }
  }

  /// Charge les commandes depuis le stockage local (après redémarrage)
  Future<List<Order>> _loadOrdersLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_ordersKey);
      if (encoded == null || encoded.isEmpty) return [];
      final List<dynamic> raw = jsonDecode(encoded);
      final orders =
          raw.map((j) => Order.fromJson(j as Map<String, dynamic>)).toList();
      if (kDebugMode) {
        debugPrint(
            '📂 ${orders.length} commandes chargées depuis le stockage local');
      }
      return orders;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Impossible de charger les commandes locales: $e');
      }
      return [];
    }
  }

  void _loadOrdersInBackground() async {
    try {
      if (kDebugMode) debugPrint('📡 [Background] Chargement des commandes...');

      // 1️⃣ Charger d'abord les commandes locales pour affichage immédiat
      final localOrders = await _loadOrdersLocally();
      if (localOrders.isNotEmpty && _orders.isEmpty) {
        _orders = localOrders;
        for (var order in _orders) {
          _lastOrderStatuses[order.id] = order.status;
        }
        try {
          notifyListeners();
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ [Background] Widget détruit: $e');
        }
        if (kDebugMode) {
          debugPrint(
              '✅ [Background] ${localOrders.length} commandes locales affichées');
        }
      }

      // 2️⃣ Synchroniser avec le serveur si un restaurant est chargé
      if (_restaurant != null) {
        final serverOrders =
            await _apiService.getOrders(restaurantId: _restaurant!.id);
        if (serverOrders.isNotEmpty) {
          // Fusionner : les commandes serveur écrasent les locales pour les IDs connus
          final Map<int, Order> merged = {for (var o in localOrders) o.id: o};
          for (var o in serverOrders) {
            merged[o.id] = o;
          }
          _orders = merged.values.toList()
            ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
          await _saveOrdersLocally(_orders);
        }
      }

      for (var order in _orders) {
        _lastOrderStatuses[order.id] = order.status;
      }

      if (kDebugMode) {
        debugPrint('✅ [Background] ${_orders.length} commandes chargées');
      }
      try {
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [Background] Widget détruit, pas de notification: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [Background] Commandes non disponibles: $e');
      }
      _orders = [];
    }
  }

  void _loadNotificationsInBackground() async {
    try {
      if (kDebugMode) {
        debugPrint('📡 [Background] Chargement des notifications...');
      }
      await loadNotifications();
      if (kDebugMode) {
        debugPrint(
            '✅ [Background] ${_notifications.length} notifications chargées');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [Background] Notifications non disponibles: $e');
      }
      _notifications = [];
    }
  }

  void _loadFlashInfosInBackground(int restaurantId) async {
    try {
      if (kDebugMode) {
        debugPrint('📡 [Background] Chargement des flash infos...');
      }
      _flashInfos = await _apiService.getFlashInfos(
        restaurantId: restaurantId,
      );
      if (kDebugMode) {
        debugPrint('✅ [Background] ${_flashInfos.length} flash infos chargées');
      }

      // ✅ Protection contre les widgets détruits
      try {
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [Background] Widget détruit, pas de notification: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [Background] Flash infos non disponibles: $e');
      }
      _flashInfos = [];
    }
  }

  Future<void> refreshAllData() async {
    if (_scannedQRCode == null) {
      if (kDebugMode) {
        debugPrint('⚠️ Impossible de rafraîchir : aucun QR code scanné');
      }
      return;
    }

    _hasApiError = false;
    _clearError();
    notifyListeners();

    try {
      final restaurantId = QRHelper.parseRestaurantId(_scannedQRCode!);

      if (restaurantId == null) {
        throw Exception('Impossible d\'extraire l\'ID lors du refresh');
      }

      if (kDebugMode) {
        debugPrint('🔄 Rafraîchissement du restaurant ID: $restaurantId');
      }

      // ✅ Passer l'ID comme int
      await loadAllInitialData(restaurantId: restaurantId);

      if (kDebugMode) debugPrint('✅ Rafraîchissement terminé');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur lors du refresh: $e');
      _setError('Impossible de rafraîchir les données');
      _hasApiError = true;
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    _isLoadingOrders = true;
    notifyListeners();

    try {
      // Charger d'abord les commandes locales
      final localOrders = await _loadOrdersLocally();
      if (localOrders.isNotEmpty && _orders.isEmpty) {
        _orders = localOrders;
      }

      // Puis synchroniser avec le serveur
      if (_restaurant != null) {
        final fetchedOrders =
            await _apiService.getOrders(restaurantId: _restaurant!.id);

        if (fetchedOrders.isNotEmpty) {
          final Map<int, Order> merged = {for (var o in localOrders) o.id: o};
          for (var o in fetchedOrders) {
            merged[o.id] = o;
          }
          _orders = merged.values.toList()
            ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

          for (var order in _orders) {
            _lastOrderStatuses[order.id] = order.status;
          }

          await _saveOrdersLocally(_orders);
          _clearError();
        }
      }
    } catch (e) {
      _setError('Erreur lors du chargement des commandes');
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  void addToCart(Dish dish, {int quantity = 1}) {
    final index = _cartItems.indexWhere((item) => item.dish.id == dish.id);
    if (index != -1) {
      _cartItems[index].quantity += quantity;
    } else {
      _cartItems.add(OrderItem(dish: dish, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(Dish dish) {
    _cartItems.removeWhere((item) => item.dish.id == dish.id);
    notifyListeners();
  }

  void updateCartItemQuantity(Dish dish, int newQuantity) {
    final index = _cartItems.indexWhere((item) => item.dish.id == dish.id);
    if (index != -1) {
      if (newQuantity > 0) {
        _cartItems[index].quantity = newQuantity;
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<int?> submitOrder({
    required String orderType,
    required String paymentMethod,
    required String phoneNumber,
    String? tableNumber,
    String? deliveryAddress,
    String? mobileMoneyProvider,
  }) async {
    _orderSubmitState = OrderSubmitState.submitting;
    _orderSubmitError = null;
    notifyListeners();
    try {
      if (_cartItems.isEmpty) throw Exception('Panier vide');
      if (_restaurant == null) throw Exception('Restaurant non défini');

      if (orderType == 'sur place' &&
          (tableNumber == null || tableNumber.trim().isEmpty)) {
        throw Exception('Numéro de table obligatoire');
      }

      final totalAmount = cartTotal;

      final List<Map<String, dynamic>> plats = _cartItems.map((item) {
        return {
          'id': item.dish.id,
          'quantite': item.quantity,
        };
      }).toList();

      String normalizeOrderType(String type) {
        switch (type.toLowerCase().trim()) {
          case 'sur place':
          case 'surplace':
            return 'sur place';
          case 'à emporter':
          case 'a emporter':
          case 'aemporter':
            return 'à emporter';
          case 'livraison':
          case 'delivery':
            return 'livraison';
          default:
            throw Exception('Type invalide: $type');
        }
      }

      final normalizedOrderType = normalizeOrderType(orderType);

      final Map<String, dynamic> orderData = {
        'total_prix': totalAmount.toInt(),
        'telephone': phoneNumber,
        'moyen_paiement': paymentMethod,
        'type': normalizedOrderType,
        'montant': totalAmount.toInt(),
        'restaurant_id': _restaurant!.id,
        'total_plats': _cartItems.length,
        'plats': plats,
      };

      if (orderType == 'sur place' && tableNumber != null) {
        orderData['table'] = tableNumber;
      }

      if (normalizedOrderType == 'livraison' && deliveryAddress != null) {
        orderData['delivery_address'] = deliveryAddress;
      }

      if (paymentMethod == 'mobile_money' && mobileMoneyProvider != null) {
        orderData['mobile_money_provider'] = mobileMoneyProvider;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.getApiUrl('commandes')),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        final newOrder = Order(
          id: responseData['id'] ?? DateTime.now().millisecondsSinceEpoch,
          items: _cartItems
              .map((item) => OrderItem(
                    dish: item.dish,
                    quantity: item.quantity,
                  ))
              .toList(),
          status: OrderStatus.pending,
          orderDate: DateTime.now(),
          paymentMethod: paymentMethod == 'cash' ? 'Espèces' : 'Mobile Money',
          table: tableNumber ?? 'À emporter',
          transactionId: responseData['transaction_id']?.toString(),
          mobileMoneyProvider: mobileMoneyProvider,
          phoneNumber: phoneNumber,
          restaurantId: _restaurant!.id.toString(),
          orderType: Order.parseOrderType(orderType),
        );

        _orders.insert(0, newOrder);
        _lastOrderStatuses[newOrder.id] = newOrder.status;
        await createOrderNotification(newOrder);
        await _saveOrdersLocally(_orders);

        // Analytics : commande passée
        unawaited(AnalyticsService.orderPlaced(
          orderId: newOrder.id,
          totalAmount: totalAmount,
          orderType: normalizedOrderType,
          paymentMethod: paymentMethod,
          restaurantId: _restaurant!.id,
          itemCount: _cartItems.length,
        ));

        _cartItems.clear();
        _orderSubmitState = OrderSubmitState.success;
        notifyListeners();

        // Analytics — MON-001
        unawaited(AnalyticsService.orderPlaced(
          orderId: newOrder.id,
          totalAmount: totalAmount,
          orderType: normalizedOrderType,
          paymentMethod: paymentMethod,
          restaurantId: _restaurant!.id,
          itemCount: newOrder.items.length,
        ));

        return newOrder.id;
      } else {
        String errorMessage = 'Erreur serveur ${response.statusCode}';

        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ??
                errorData['error'] ??
                errorData.toString();
          } catch (e) {
            errorMessage = response.body;
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      _orderSubmitState = OrderSubmitState.error;
      _orderSubmitError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Réinitialise l'état de soumission (à appeler avant de réouvrir le formulaire)
  void resetOrderSubmitState() {
    _orderSubmitState = OrderSubmitState.idle;
    _orderSubmitError = null;
    notifyListeners();
  }

  List<Dish> get availableDishes =>
      _dishes.where((d) => d.isAvailable).toList();

  bool get hasData => _restaurant != null;

  String get cartSummary {
    if (_cartItems.isEmpty) return 'Panier vide';
    return _cartItems
        .map((item) =>
            '${item.dish.name} x${item.quantity} = ${item.totalPrice.toStringAsFixed(0)} FCFA')
        .join(', ');
  }

  void _setError(String message) {
    _error = message;
  }

  void _clearError() {
    _error = null;
  }

  List<Dish> filterDishesByCategory(dynamic categoryId) {
    if (categoryId == null || categoryId == 0) {
      return _dishes;
    }
    return _dishes.where((dish) => dish.categoryId == categoryId).toList();
  }

  List<Dish> loadDishes() {
    return _dishes;
  }

  void debugPrintState() {
    if (!kDebugMode) return;
    debugPrint('=== ÉTAT DU PROVIDER ===');
    debugPrint('Restaurant: ${_restaurant?.name ?? "Aucun"}');
    debugPrint('Commandes: ${_orders.length}');
    debugPrint(
        'Notifications: ${_notifications.length} ($unreadNotificationsCount non lues)');
    debugPrint('Pusher connecté: $_isRealtimeConnected');
    debugPrint(
        'Auto-refresh: ${_autoRefreshTimer?.isActive ?? false ? "Actif" : "Inactif"}');
    debugPrint('========================');
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// ✅ Réinitialisation COMPLÈTE (y compris Pusher) - utilisé lors de la déconnexion
  void resetAllData() {
    if (kDebugMode) {
      debugPrint('🔄 Réinitialisation COMPLÈTE (avec déconnexion Pusher)...');
    }

    // Arrêter l'auto-refresh
    _autoRefreshTimer?.cancel();

    // Déconnecter Pusher
    try {
      _realtimeService.disconnect();
      _realtimeService.clearCallbacks();
      _isRealtimeConnected = false;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Erreur déconnexion Pusher: $e');
    }

    // Réinitialiser les états
    _isLoading = false;
    _hasApiError = false;
    _error = null;
    _isLoadingOrders = false;

    // Vider toutes les données
    _restaurant = null;
    _dishes = [];
    _dishesOfTheDay = [];
    _flashInfos = [];
    _categories = [];
    _orders = [];
    _notifications = [];
    _cartItems.clear();
    _lastOrderStatuses.clear();

    // Effacer les commandes persistées localement
    SharedPreferences.getInstance().then((prefs) => prefs.remove(_ordersKey));

    // Réinitialiser le QR Code
    _scannedQRCode = null;

    // Réinitialiser la navigation
    _currentNavIndex = 0;

    // Nettoyer le cache
    ApiConfig.clearValidationCache();

    if (kDebugMode) debugPrint('✅ Réinitialisation complète terminée');

    notifyListeners();
  }
}
