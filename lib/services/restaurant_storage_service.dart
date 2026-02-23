import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RestaurantStorageService {
  static const String _keyRestaurantData = 'restaurant_data';
  static const String _keyRestaurantId = 'restaurant_id';
  static const String _keyIsScanned = 'is_restaurant_scanned';

  /// Sauvegarder les données du restaurant après scan
  static Future<void> saveRestaurantData({
    required String restaurantId,
    required Map<String, dynamic> restaurantData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRestaurantId, restaurantId);
    await prefs.setString(_keyRestaurantData, jsonEncode(restaurantData));
    await prefs.setBool(_keyIsScanned, true);
  }

  /// Vérifier si un restaurant a déjà été scanné
  static Future<bool> isRestaurantScanned() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsScanned) ?? false;
  }

  /// Récupérer l'ID du restaurant scanné
  static Future<String?> getRestaurantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRestaurantId);
  }

  /// Récupérer les données complètes du restaurant
  static Future<Map<String, dynamic>?> getRestaurantData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyRestaurantData);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  /// Effacer les données (déconnexion/changement de restaurant)
  static Future<void> clearRestaurantData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRestaurantData);
    await prefs.remove(_keyRestaurantId);
    await prefs.setBool(_keyIsScanned, false);
  }
}