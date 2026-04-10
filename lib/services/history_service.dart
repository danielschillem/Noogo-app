import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class VisitedRestaurant {
  final String id;
  final String name;
  final String imageUrl;

  VisitedRestaurant(
      {required this.id, required this.name, required this.imageUrl});
}

class HistoryService {
  static const String _visitedKey = 'visited_restaurants';
  static const int _maxHistory = 20;

  /// Retourne la liste des restaurants visités avec leurs vrais détails depuis l'API.
  Future<List<VisitedRestaurant>> getVisitedRestaurants() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids = prefs.getStringList(_visitedKey) ?? [];

    if (ids.isEmpty) return [];

    final apiService = ApiService();
    final results = <VisitedRestaurant>[];

    for (final id in ids) {
      try {
        final restaurantId = int.tryParse(id);
        if (restaurantId == null) continue;

        final menuData =
            await apiService.getRestaurantMenu(restaurantId: restaurantId);
        final restaurant = menuData.restaurant;

        final imageUrl = ApiConfig.getFullImageUrl(
          restaurant.logo?.isNotEmpty == true
              ? restaurant.logo
              : (restaurant.images.isNotEmpty ? restaurant.images.first : null),
        );

        results.add(VisitedRestaurant(
          id: id,
          name: restaurant.nom,
          imageUrl: imageUrl,
        ));
      } catch (_) {
        // Ignorer les restaurants inaccessibles (hors-ligne, supprimés…)
      }
    }

    return results;
  }

  /// Ajoute un restaurant à l'historique (garde les 20 plus récents).
  static Future<void> addVisitedRestaurant(String restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_visitedKey) ?? [];

    ids.remove(restaurantId); // évite les doublons
    ids.insert(0, restaurantId);

    if (ids.length > _maxHistory) ids.removeRange(_maxHistory, ids.length);

    await prefs.setStringList(_visitedKey, ids);
  }

  /// Vide l'historique complet.
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_visitedKey);
  }
}
