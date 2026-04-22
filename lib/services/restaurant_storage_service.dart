import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/saved_restaurant.dart';

class RestaurantStorageService {
  // ─── Clés legacy (compat SplashChecker) ─────────────────────────────────
  static const String _keyRestaurantData = 'restaurant_data';
  static const String _keyRestaurantId = 'restaurant_id';
  static const String _keyIsScanned = 'is_restaurant_scanned';

  // ─── Clés multi-restaurants ──────────────────────────────────────────────
  static const String _keySavedList = 'saved_restaurants_list';
  static const String _keyLastRestaurantId = 'last_restaurant_id';

  // =========================================================================
  // API LEGACY - utilisée par SplashChecker (lecture seule désormais)
  // =========================================================================

  /// Vérifier si au moins un restaurant est sauvegardé
  static Future<bool> isRestaurantScanned() async {
    final prefs = await SharedPreferences.getInstance();
    // Priorité : nouvelle liste, fallback legacy
    final list = prefs.getString(_keySavedList);
    if (list != null) {
      final parsed = _parseList(list);
      return parsed.isNotEmpty;
    }
    return prefs.getBool(_keyIsScanned) ?? false;
  }

  /// Retourne l'ID du DERNIER restaurant utilisé (string, compat legacy)
  static Future<String?> getRestaurantId() async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_keyLastRestaurantId);
    if (lastId != null) return lastId.toString();
    return prefs.getString(_keyRestaurantId);
  }

  /// Récupérer les données brutes du restaurant (legacy)
  static Future<Map<String, dynamic>?> getRestaurantData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyRestaurantData);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  /// Sauvegarde legacy utilisée par WelcomeScreen.
  /// Appelle aussi [addOrUpdateRestaurant] pour la liste multi.
  static Future<void> saveRestaurantData({
    required String restaurantId,
    required Map<String, dynamic> restaurantData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRestaurantId, restaurantId);
    await prefs.setString(_keyRestaurantData, jsonEncode(restaurantData));
    await prefs.setBool(_keyIsScanned, true);
  }

  /// Efface TOUT (déconnexion complète - retire aussi de la liste multi)
  static Future<void> clearRestaurantData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRestaurantData);
    await prefs.remove(_keyRestaurantId);
    await prefs.setBool(_keyIsScanned, false);
    // Ne supprime pas la liste multi : l'utilisateur garde ses restaurants
  }

  // =========================================================================
  // API MULTI-RESTAURANTS
  // =========================================================================

  /// Ajoute ou met à jour un restaurant dans la liste persistante.
  /// Si le restaurant existe déjà, met à jour [lastScannedAt].
  static Future<void> addOrUpdateRestaurant(SavedRestaurant restaurant) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedRestaurants();

    final idx = list.indexWhere((r) => r.id == restaurant.id);
    if (idx >= 0) {
      list[idx] = restaurant.copyWith(lastScannedAt: DateTime.now());
    } else {
      list.insert(0, restaurant);
    }

    await prefs.setString(
        _keySavedList, SavedRestaurant.listToJsonString(list));
    await prefs.setInt(_keyLastRestaurantId, restaurant.id);
  }

  /// Définit le dernier restaurant utilisé (sans modifier la liste).
  static Future<void> setLastRestaurantId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastRestaurantId, id);
  }

  /// Retourne tous les restaurants sauvegardés, triés du plus récent au plus ancien.
  static Future<List<SavedRestaurant>> getSavedRestaurants() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySavedList);
    if (raw == null) return [];
    return _parseList(raw);
  }

  /// Supprime un restaurant de la liste (sans toucher au restaurant courant).
  static Future<void> removeRestaurant(int restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedRestaurants();
    list.removeWhere((r) => r.id == restaurantId);
    await prefs.setString(
        _keySavedList, SavedRestaurant.listToJsonString(list));

    // Si c'était le dernier restaurant actif, mettre à jour
    final lastId = prefs.getInt(_keyLastRestaurantId);
    if (lastId == restaurantId) {
      if (list.isNotEmpty) {
        await prefs.setInt(_keyLastRestaurantId, list.first.id);
      } else {
        await prefs.remove(_keyLastRestaurantId);
        await prefs.setBool(_keyIsScanned, false);
      }
    }
  }

  /// Efface toute la liste multi-restaurants.
  static Future<void> clearAllRestaurants() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedList);
    await prefs.remove(_keyLastRestaurantId);
    await prefs.remove(_keyRestaurantData);
    await prefs.remove(_keyRestaurantId);
    await prefs.setBool(_keyIsScanned, false);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static List<SavedRestaurant> _parseList(String raw) {
    try {
      return SavedRestaurant.listFromJsonString(raw)
        ..sort((a, b) => b.lastScannedAt.compareTo(a.lastScannedAt));
    } catch (_) {
      return [];
    }
  }
}
