import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion des plats favoris (persisté localement)
class FavoritesService {
  static const String _key = 'favorite_dish_ids';

  /// Charger les IDs des plats favoris
  static Future<Set<int>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  /// Sauvegarder l'ensemble des favoris
  static Future<void> _save(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.map((e) => e.toString()).toList());
  }

  /// Ajouter un plat aux favoris
  static Future<Set<int>> addFavorite(int dishId) async {
    final ids = await loadFavorites();
    ids.add(dishId);
    await _save(ids);
    return ids;
  }

  /// Retirer un plat des favoris
  static Future<Set<int>> removeFavorite(int dishId) async {
    final ids = await loadFavorites();
    ids.remove(dishId);
    await _save(ids);
    return ids;
  }

  /// Basculer l'état favori d'un plat
  static Future<Set<int>> toggleFavorite(int dishId) async {
    final ids = await loadFavorites();
    if (ids.contains(dishId)) {
      ids.remove(dishId);
    } else {
      ids.add(dishId);
    }
    await _save(ids);
    return ids;
  }

  /// Vider tous les favoris
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
