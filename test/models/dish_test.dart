import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/order.dart';

void main() {
  setUpAll(() async {
    // Initialiser dotenv pour Ã©viter NotInitializedError dans ApiConfig/AppLogger
    await dotenv.load(
      fileName: 'assets/env/.env',
      isOptional: true,
      mergeWith: {
        'API_BASE_URL': 'http://localhost/api',
        'ENVIRONMENT': 'test'
      },
    );
  });
  group('Dish.fromJson', () {
    test('parse un plat complet depuis JSON API', () {
      final json = {
        'id': 1,
        'nom': 'Riz sauce tomate',
        'description': 'Riz avec sauce tomate maison',
        'prix': 1500,
        'images': ['storage/dishes/riz.jpg'],
        'disponibilite': true,
        'is_plat_du_jour': false,
        'temps_preparation': 15,
        'category_id': 2,
        'categorie': 'Plats chauds',
      };

      final dish = Dish.fromJson(json);

      expect(dish.id, 1);
      expect(dish.name, 'Riz sauce tomate');
      expect(dish.description, 'Riz avec sauce tomate maison');
      expect(dish.price, 1500.0);
      expect(dish.isAvailable, true);
      expect(dish.isDishOfTheDay, false);
      expect(dish.preparationTime, 15);
      expect(dish.categoryId, 2);
      expect(dish.category, 'Plats chauds');
    });

    test('utilise des valeurs par dÃ©faut pour les champs manquants', () {
      final json = {
        'id': 2,
        'nom': 'Plat mystÃ¨re',
        'prix': '2000',
      };

      final dish = Dish.fromJson(json);

      expect(dish.id, 2);
      expect(dish.name, 'Plat mystÃ¨re');
      expect(dish.price, 2000.0);
      expect(dish.description, '');
      expect(dish.isAvailable, true);
      expect(dish.isDishOfTheDay, false);
      expect(dish.preparationTime, 0);
    });

    test('accepte le prix comme String', () {
      final json = {
        'id': 3,
        'nom': 'Poulet braisÃ©',
        'prix': '3500',
        'disponibilite': 1,
      };

      final dish = Dish.fromJson(json);
      expect(dish.price, 3500.0);
    });

    test('gÃ¨re les images null ou vides', () {
      final jsonNull = {'id': 4, 'nom': 'Test', 'prix': 500, 'images': null};
      final jsonEmpty = {'id': 5, 'nom': 'Test', 'prix': 500, 'images': []};

      final dishNull = Dish.fromJson(jsonNull);
      final dishEmpty = Dish.fromJson(jsonEmpty);

      // Les deux doivent utiliser l'image par dÃ©faut sans planterx
      expect(dishNull.imageUrl, isNotEmpty);
      expect(dishEmpty.imageUrl, isNotEmpty);
    });

    test('accepte une URL d\'image http complÃ¨te directement', () {
      final json = {
        'id': 6,
        'nom': 'Burger',
        'prix': 2500,
        'images': ['https://example.com/burger.jpg'],
      };

      final dish = Dish.fromJson(json);
      expect(dish.imageUrl, 'https://example.com/burger.jpg');
    });

    test('formattedPrice retourne le format FCFA', () {
      final json = {'id': 7, 'nom': 'Jus', 'prix': 500};
      final dish = Dish.fromJson(json);
      expect(dish.formattedPrice, contains('500'));
      expect(dish.formattedPrice, contains('FCFA'));
    });
  });

  group('OrderItem', () {
    Dish makeDish({int id = 1, double price = 1000}) => Dish(
          id: id,
          name: 'Plat test',
          description: '',
          price: price,
          imageUrl: '',
          categoryId: 1,
          category: 'Test',
          isAvailable: true,
        );

    test('calcule totalPrice correctement', () {
      final item = OrderItem(dish: makeDish(price: 1500), quantity: 3);
      expect(item.totalPrice, 4500.0);
    });

    test('totalPrice est 0 pour quantitÃ© 0', () {
      final item = OrderItem(dish: makeDish(price: 1000), quantity: 0);
      expect(item.totalPrice, 0.0);
    });
  });
}
