
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart'; //

class VisitedRestaurant {
  final String id;
  final String name;
  final String imageUrl;

  VisitedRestaurant({required this.id, required this.name, required this.imageUrl});

  // Simple factory pour créer un objet depuis un JSON (simulé ici)
  factory VisitedRestaurant.fromJson(Map<String, dynamic> json) {
    return VisitedRestaurant(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
    );
  }
}

class HistoryService {

  // Méthode pour obtenir la liste des restaurants visités
  Future<List<VisitedRestaurant>> getVisitedRestaurants() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids = prefs.getStringList('visited_restaurants') ?? [];

    if (ids.isEmpty) {
      return []; // Retourne une liste vide si aucun historique
    }

    // Idéalement, ici vous feriez un appel à votre API
    // pour récupérer les détails de chaque restaurant par son ID.
    // Exemple : final restaurantsDetails = await myApiService.getRestaurantsByIds(ids);

    // Pour cet exemple, nous simulons la réponse :
    List<VisitedRestaurant> visitedList = [];
    for (var id in ids) {
      // Remplacez ceci par un vrai appel API qui retourne les détails pour 'id'
      visitedList.add(await _fetchRestaurantDetails(id));
    }

    return visitedList;
  }

  // Méthode de simulation d'un appel API
  Future<VisitedRestaurant> _fetchRestaurantDetails(String id) async {
    // SIMULATION: En pratique, ce serait un appel HTTP GET
    // par exemple: http.get(Uri.parse('https://votre-api.com/restaurants/$id'))
    await Future.delayed(const Duration(milliseconds: 50)); // Simule la latence réseau
    return VisitedRestaurant(
        id: id,
        name: 'Restaurant Fictif $id',
        imageUrl: 'https://via.placeholder.com/150/92c952/FFFFFF?Text=Resto+$id'
    );
  }
}
