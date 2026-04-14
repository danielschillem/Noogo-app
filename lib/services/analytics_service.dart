import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/app_logger.dart';

/// Service d'analytics — MON-001
///
/// Trace les événements clés de l'application (scan QR, commande, paiement…).
/// En mode debug, les événements sont loggés localement via AppLogger.
/// En mode production et si [ApiConfig.analyticsEndpoint] est configuré,
/// les événements sont envoyés au backend ou à un service analytics tiers.
///
/// Pour migrer vers Mixpanel / PostHog / Firebase, il suffit de modifier
/// [_send] — le reste du code ne change pas.
class AnalyticsService {
  AnalyticsService._();

  // ================================================================
  // ÉVÉNEMENTS QR CODE
  // ================================================================

  /// Utilisateur scanne un QR code restaurant.
  static Future<void> qrScanned(int restaurantId) async {
    await _track('qr_scanned', {
      'restaurant_id': restaurantId,
    });
  }

  /// Validation du QR code réussie.
  static Future<void> qrValidated(
      int restaurantId, String restaurantName) async {
    await _track('qr_validated', {
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
    });
  }

  // ================================================================
  // ÉVÉNEMENTS MENU
  // ================================================================

  /// Plat ajouté au panier.
  static Future<void> dishAddedToCart({
    required int dishId,
    required String dishName,
    required double price,
    required int restaurantId,
  }) async {
    await _track('dish_added_to_cart', {
      'dish_id': dishId,
      'dish_name': dishName,
      'price': price,
      'restaurant_id': restaurantId,
    });
  }

  /// Plat retiré du panier.
  static Future<void> dishRemovedFromCart(int dishId) async {
    await _track('dish_removed_from_cart', {'dish_id': dishId});
  }

  /// Plat ajouté ou retiré des favoris.
  static Future<void> dishFavoriteToggled(int dishId, bool isFavorite) async {
    await _track('dish_favorite_toggled', {
      'dish_id': dishId,
      'is_favorite': isFavorite,
    });
  }

  // ================================================================
  // ÉVÉNEMENTS COMMANDE
  // ================================================================

  /// Commande soumise avec succès.
  static Future<void> orderPlaced({
    required int orderId,
    required double totalAmount,
    required String orderType, // 'sur place' | 'à emporter' | 'livraison'
    required String paymentMethod, // 'cash' | 'mobile_money'
    required int restaurantId,
    required int itemCount,
  }) async {
    await _track('order_placed', {
      'order_id': orderId,
      'total_amount': totalAmount,
      'order_type': orderType,
      'payment_method': paymentMethod,
      'restaurant_id': restaurantId,
      'item_count': itemCount,
    });
  }

  /// Commande annulée par l'utilisateur.
  static Future<void> orderCancelled(int orderId) async {
    await _track('order_cancelled', {'order_id': orderId});
  }

  /// Commande notée par l'utilisateur.
  static Future<void> orderRated(int orderId, int stars) async {
    await _track('order_rated', {'order_id': orderId, 'stars': stars});
  }

  // ================================================================
  // ÉVÉNEMENTS PAIEMENT
  // ================================================================

  /// Paiement Mobile Money initié.
  static Future<void> paymentInitiated({
    required String method,
    required double amount,
  }) async {
    await _track('payment_initiated', {'method': method, 'amount': amount});
  }

  /// Paiement réussi.
  static Future<void> paymentSuccess(String method, double amount) async {
    await _track('payment_success', {'method': method, 'amount': amount});
  }

  /// Paiement échoué.
  static Future<void> paymentFailed(String method, String reason) async {
    await _track('payment_failed', {'method': method, 'reason': reason});
  }

  // ================================================================
  // ÉVÉNEMENTS NAVIGATION
  // ================================================================

  /// Écran ouvert.
  static Future<void> screenViewed(String screenName) async {
    await _track('screen_viewed', {'screen': screenName});
  }

  // ================================================================
  // ÉVÉNEMENTS UTILISATEUR
  // ================================================================

  /// Connexion réussie.
  static Future<void> userLoggedIn(String method) async {
    await _track('user_logged_in', {'method': method}); // 'email' | 'phone'
  }

  /// Connexion en mode invité.
  static Future<void> guestModeEntered() async {
    await _track('guest_mode_entered', {});
  }

  /// Déconnexion.
  static Future<void> userLoggedOut() async {
    await _track('user_logged_out', {});
  }

  // ================================================================
  // MOTEUR INTERNE
  // ================================================================

  /// Enregistre un événement avec ses propriétés.
  static Future<void> _track(
    String eventName,
    Map<String, dynamic> properties,
  ) async {
    final payload = {
      'event': eventName,
      'timestamp': DateTime.now().toIso8601String(),
      'environment': ApiConfig.environment,
      'properties': properties,
    };

    // ✅ Toujours logger en debug
    AppLogger.debug('📊 Analytics: $eventName $properties', tag: 'Analytics');

    // ✅ Envoyer seulement en production si l'endpoint est configuré
    if (ApiConfig.isProduction) {
      await _send(payload);
    }
  }

  /// Envoie l'événement vers le backend analytics.
  /// À remplacer par l'SDK Mixpanel / PostHog / Firebase selon le besoin.
  static Future<void> _send(Map<String, dynamic> payload) async {
    final endpoint = ApiConfig.analyticsEndpoint;
    if (endpoint.isEmpty) return;

    try {
      await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silencieux — analytics ne doit jamais faire crasher l'app
      if (kDebugMode) {
        debugPrint('⚠️ Analytics send failed: $e');
      }
    }
  }
}
