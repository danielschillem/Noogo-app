import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/dish.dart';
import '../models/flash_info.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../config/api_config.dart';
import '../utils/api_exceptions.dart';
import 'auth_service.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  ApiService._internal();
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;

  Map<String, dynamic> _decodeJsonMapOrThrow({
    required String body,
    required Uri uri,
    required String method,
    required int statusCode,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return <String, dynamic>{};

    try {
      final decoded = json.decode(trimmed);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ParseException(
        'Réponse API inattendue ($method $uri): JSON non-objet.',
      );
    } on FormatException catch (e) {
      final preview = trimmed.length > 220
          ? '${trimmed.substring(0, 220)}...'
          : trimmed;
      final looksHtml = trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html');
      final hint = looksHtml
          ? 'Le serveur a renvoyé du HTML au lieu de JSON (URL/API ou proxy à vérifier).'
          : 'Le serveur a renvoyé un format non JSON.';
      throw ParseException(
        'Réponse JSON invalide ($method $uri, HTTP $statusCode): $hint Détail: $e. Aperçu: $preview',
      );
    }
  }

  /// Construit les headers avec le token Bearer si l'utilisateur est connecté
  Future<Map<String, String>> _buildHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Méthodes génériques GET / POST
  Future<Map<String, dynamic>?> _get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    const maxRetries = 2;
    int attempt = 0;

    while (true) {
      try {
        if (kDebugMode) {
          debugPrint(
              '📡 API GET: $uri${attempt > 0 ? ' (retry $attempt)' : ''}');
        }

        final headers = await _buildHeaders();
        final response = await http.get(uri, headers: headers).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException('Timeout GET'),
            );

        if (kDebugMode) debugPrint('📡 Réponse: ${response.statusCode}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _decodeJsonMapOrThrow(
            body: response.body,
            uri: uri,
            method: 'GET',
            statusCode: response.statusCode,
          );
        } else {
          if (kDebugMode) {
            debugPrint(
                'Erreur HTTP GET: ${response.statusCode} - ${response.body}');
          }
          throw ApiException.fromStatusCode(response.statusCode, response.body);
        }
      } on TimeoutException catch (e) {
        attempt++;
        if (kDebugMode) {
          debugPrint('⚠️ Timeout GET (tentative $attempt/$maxRetries): $e');
        }
        if (attempt > maxRetries) {
          throw const NetworkException(
              'Impossible de se connecter au serveur.');
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } on http.ClientException catch (e) {
        attempt++;
        if (kDebugMode) {
          debugPrint(
              '⚠️ Réseau indisponible GET (tentative $attempt/$maxRetries): $e');
        }
        if (attempt > maxRetries) {
          throw const NetworkException(
              'Impossible de se connecter au serveur.');
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } on ApiException {
        rethrow;
      } catch (e) {
        // Handles SocketException on mobile without importing dart:io
        if (e.runtimeType.toString().contains('SocketException')) {
          attempt++;
          if (kDebugMode) {
            debugPrint(
                '⚠️ Réseau indisponible GET (tentative $attempt/$maxRetries): $e');
          }
          if (attempt > maxRetries) {
            throw const NetworkException(
                'Impossible de se connecter au serveur.');
          }
          await Future.delayed(Duration(seconds: attempt * 2));
        } else {
          if (kDebugMode) debugPrint('Erreur GET: $e');
          rethrow;
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _post(
      String endpoint, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    const maxRetries = 2;
    int attempt = 0;

    while (true) {
      try {
        final headers = await _buildHeaders();
        final response = await http
            .post(uri, headers: headers, body: json.encode(data))
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException('Timeout POST'),
            );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _decodeJsonMapOrThrow(
            body: response.body,
            uri: uri,
            method: 'POST',
            statusCode: response.statusCode,
          );
        } else {
          if (kDebugMode) {
            debugPrint(
                'Erreur HTTP POST: ${response.statusCode} - ${response.body}');
          }
          throw ApiException.fromStatusCode(response.statusCode, response.body);
        }
      } on TimeoutException catch (e) {
        attempt++;
        if (kDebugMode) {
          debugPrint('⚠️ Timeout POST (tentative $attempt/$maxRetries): $e');
        }
        if (attempt > maxRetries) {
          throw const NetworkException(
              'Impossible de se connecter au serveur.');
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } on http.ClientException catch (e) {
        attempt++;
        if (kDebugMode) {
          debugPrint(
              '⚠️ Réseau indisponible POST (tentative $attempt/$maxRetries): $e');
        }
        if (attempt > maxRetries) {
          throw const NetworkException(
              'Impossible de se connecter au serveur.');
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } on ApiException {
        rethrow;
      } catch (e) {
        // Handles SocketException on mobile without importing dart:io
        if (e.runtimeType.toString().contains('SocketException')) {
          attempt++;
          if (kDebugMode) {
            debugPrint(
                '⚠️ Réseau indisponible POST (tentative $attempt/$maxRetries): $e');
          }
          if (attempt > maxRetries) {
            throw const NetworkException(
                'Impossible de se connecter au serveur.');
          }
          await Future.delayed(Duration(seconds: attempt * 2));
        } else {
          if (kDebugMode) debugPrint('Erreur POST: $e');
          rethrow;
        }
      }
    }
  }

  // ===================================================================
  // NOUVELLE MÉTHODE : Récupère TOUT le menu en une seule requête
  // ===================================================================
  Future<RestaurantMenuData> getRestaurantMenu(
      {required int restaurantId}) async {
    try {
      if (kDebugMode) {
        debugPrint('📡 === API getRestaurantMenu ===');
        debugPrint('   - Restaurant ID: $restaurantId');
      }

      final data = await _get('/restaurant/$restaurantId/menu');
      if (data == null || data.isEmpty) {
        if (kDebugMode) debugPrint('❌ Aucune donnée reçue de l\'API');
        throw Exception('Aucune donnée reçue de l\'API');
      }
      if (kDebugMode) debugPrint('✅ Données brutes reçues: ${data.keys}');
      if (!data.containsKey('data')) {
        if (kDebugMode)
          debugPrint('❌ Clé "data" manquante. Clés présentes: ${data.keys}');
        throw Exception('Structure de réponse invalide');
      }

      final menuData = data['data'] as Map<String, dynamic>;
      if (kDebugMode) debugPrint('✅ Contenu de menuData: ${menuData.keys}');

      // Extraire le restaurant
      final restaurantJson = menuData['restaurant'] as Map<String, dynamic>;
      final restaurant = Restaurant.fromJson(restaurantJson);

      // Extraire les plats du jour
      final List<dynamic> platsDuJourList = menuData['plats_du_jour'] ?? [];
      final dishesOfTheDay = platsDuJourList
          .map((json) => Dish.fromJson(json as Map<String, dynamic>))
          .toList();

      // Extraire les catégories et tous les plats
      final List<dynamic> menuParCategories =
          menuData['menu_par_categories'] ?? [];
      final categories = <Category>[];
      final allDishes = <Dish>[];

      for (var categoryData in menuParCategories) {
        final categoryJson = categoryData as Map<String, dynamic>;

        // Créer la catégorie
        final category = Category.fromJson(categoryJson);
        categories.add(category);

        // Extraire les plats de cette catégorie
        final List<dynamic> platsJson = categoryJson['plats'] ?? [];
        final categoryId = categoryJson['categorie_id'] as int;

        for (var platJson in platsJson) {
          final platMap = platJson as Map<String, dynamic>;
          // Ajouter le category_id au plat s'il n'existe pas déjà
          platMap['categorie_id'] = categoryId;

          final dish = Dish.fromJson(platMap);
          allDishes.add(dish);
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Menu chargé: ${restaurant.nom}');
        debugPrint('   - ${allDishes.length} plats');
        debugPrint('   - ${dishesOfTheDay.length} plats du jour');
        debugPrint('   - ${categories.length} catégories');
      }

      return RestaurantMenuData(
        restaurant: restaurant,
        dishes: allDishes,
        dishesOfTheDay: dishesOfTheDay,
        categories: categories,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ ERREUR ApiService.getRestaurantMenu: $e');
        debugPrint('📍 Stack: $stackTrace');
      }
      rethrow;
    }
  }

// Flash infos (offres actives)

  Future<List<FlashInfo>> getFlashInfos({required int restaurantId}) async {
    try {
      if (kDebugMode) debugPrint('📡 Appel API: /offres/actives/$restaurantId');

      final data = await _get('/offres/actives/$restaurantId');

      if (data == null) {
        if (kDebugMode)
          debugPrint('⚠️ Aucune donnée reçue pour les offres actives');
        return [];
      }

      if (kDebugMode)
        debugPrint('✅ Données offres actives reçues: ${data.keys}');

      final List<dynamic> list = data['data'] ??
          data['offres'] ??
          data['flash_infos'] ??
          (data is List ? data : []);

      if (kDebugMode)
        debugPrint('📋 Liste offres actives: ${list.length} éléments');

      if (list.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Liste vide, vérifiez la structure de la réponse API');
          debugPrint('📋 Structure complète: $data');
        }
      }

      return list.map((json) => FlashInfo.fromJson(json)).toList();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('⚠️ ApiService-getFlashInfos: Erreur ($e)');
        debugPrint('📍 Stack: $stackTrace');
      }
      return [];
    }
  }

  // ===================================================================
  // Orders & Notifications (OPTIONNELS - Ne font pas crasher l'app)
  // ===================================================================
  Future<List<Order>> getOrders({required int restaurantId}) async {
    try {
      // Ne pas appeler si non authentifié (évite les 401 en boucle)
      final token = await AuthService.getToken();
      if (token == null) return [];

      final data = await _get('/restaurants/$restaurantId/orders');
      if (data == null) return [];
      final List<dynamic> list = data['data'] ?? [];
      return list.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode)
        debugPrint('⚠️ ApiService-getOrders: Endpoint non disponible ($e)');
      return [];
    }
  }

  Future<Order?> placeOrder(Order order) async {
    try {
      final data = await _post('/orders', order.toJson());
      if (data == null) return null;
      return Order.fromJson(data['data']);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to place order via API: $e');
      return null;
    }
  }

  /// Recherche de restaurants par nom/adresse (public, avec retry et token si dispo).
  Future<List<Map<String, dynamic>>> searchRestaurants(String query) async {
    final endpoint = query.isEmpty
        ? '/restaurants/search'
        : '/restaurants/search?q=${Uri.encodeQueryComponent(query)}';
    final data = await _get(endpoint);
    if (data == null) return [];
    final list = data['data'];
    if (list is List) return List<Map<String, dynamic>>.from(list);
    return [];
  }

  /// Valide un coupon pour un restaurant (avec retry et token si dispo).
  Future<Map<String, dynamic>?> validateCoupon({
    required String code,
    required int restaurantId,
    required double orderTotal,
  }) async {
    return _post('/coupons/validate', {
      'code': code,
      'restaurant_id': restaurantId,
      'order_total': orderTotal,
    });
  }
}

// ===================================================================
// Classe helper pour regrouper les données du menu
// ===================================================================
class RestaurantMenuData {
  final Restaurant restaurant;
  final List<Dish> dishes;
  final List<Dish> dishesOfTheDay;
  final List<Category> categories;

  RestaurantMenuData({
    required this.restaurant,
    required this.dishes,
    required this.dishesOfTheDay,
    required this.categories,
  });
}
