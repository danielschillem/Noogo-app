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

  group('Dish.toJson', () {
    Dish makeDish() => Dish(
          id: 1,
          name: 'Test',
          description: 'Desc',
          price: 1500,
          imageUrl: 'https://example.com/img.jpg',
          categoryId: 2,
          category: 'Cat',
          isAvailable: true,
          isDishOfTheDay: false,
        );

    test('toJson contient toutes les clés attendues', () {
      final json = makeDish().toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('price'), isTrue);
      expect(json.containsKey('category_id'), isTrue);
      expect(json.containsKey('is_available'), isTrue);
    });

    test('toJson valeurs correctes', () {
      final json = makeDish().toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Test');
      expect(json['price'], 1500.0);
    });
  });

  group('Dish.copyWith', () {
    final original = Dish(
      id: 1,
      name: 'Original',
      description: 'Desc',
      price: 1000,
      imageUrl: '',
      categoryId: 1,
      category: 'Cat',
      isAvailable: true,
    );

    test('copyWith change le nom', () {
      final copy = original.copyWith(name: 'Nouveau');
      expect(copy.name, 'Nouveau');
      expect(copy.id, 1);
    });

    test('copyWith change le prix', () {
      final copy = original.copyWith(price: 2000);
      expect(copy.price, 2000.0);
    });

    test('copyWith sans argument retourne copie identique', () {
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.name, original.name);
    });
  });

  group('Dish.toString et equality', () {
    final dish = Dish(
      id: 5,
      name: 'Burger',
      description: '',
      price: 3000,
      imageUrl: '',
      categoryId: 1,
      category: 'Fast Food',
      isAvailable: true,
    );

    test('toString contient le nom', () {
      expect(dish.toString(), contains('Burger'));
    });

    test('egalite: meme id → true', () {
      final d2 = Dish(
        id: 5,
        name: 'Autre nom',
        description: '',
        price: 100,
        imageUrl: '',
        categoryId: 1,
        category: '',
        isAvailable: false,
      );
      expect(dish == d2, isTrue);
    });

    test('egalite: id different → false', () {
      final d2 = dish.copyWith(id: 99);
      expect(dish == d2, isFalse);
    });

    test('hashCode: meme id → meme hash', () {
      final d2 = dish.copyWith(name: 'Autre');
      expect(dish.hashCode, d2.hashCode);
    });
  });

  group('Dish.fromJson variantes images', () {
    test('image en string directe (pas liste)', () {
      final dish = Dish.fromJson({
        'id': 10,
        'nom': 'Test',
        'prix': 500,
        'images': 'storage/img.jpg',
      });
      expect(dish.imageUrl, isA<String>());
    });

    test('image Map avec clé url', () {
      final dish = Dish.fromJson({
        'id': 11,
        'nom': 'Test2',
        'prix': 700,
        'images': {'url': 'https://example.com/x.jpg'},
      });
      expect(dish.imageUrl, isA<String>());
    });

    test('image Map avec clé chemin', () {
      final dish = Dish.fromJson({
        'id': 12,
        'nom': 'Test3',
        'prix': 800,
        'images': {'chemin': 'storage/img.png'},
      });
      expect(dish.imageUrl, isA<String>());
    });

    test('image liste avec Map url', () {
      final dish = Dish.fromJson({
        'id': 13,
        'nom': 'Test4',
        'prix': 900,
        'images': [
          {'url': 'https://example.com/y.jpg'}
        ],
      });
      expect(dish.imageUrl, isA<String>());
    });

    test('image liste avec Map chemin', () {
      final dish = Dish.fromJson({
        'id': 14,
        'nom': 'Test5',
        'prix': 1000,
        'images': [
          {'chemin': 'storage/img2.jpg'}
        ],
      });
      expect(dish.imageUrl, isA<String>());
    });

    test('disponibilite string "1" → true', () {
      final dish = Dish.fromJson({
        'id': 15,
        'nom': 'Test6',
        'prix': 500,
        'disponibilite': '1',
      });
      expect(dish.isAvailable, isTrue);
    });

    test('disponibilite string "true" → true', () {
      final dish = Dish.fromJson({
        'id': 16,
        'nom': 'Test7',
        'prix': 500,
        'disponibilite': 'true',
      });
      expect(dish.isAvailable, isTrue);
    });

    test('prix avec virgule → double', () {
      final dish = Dish.fromJson({
        'id': 17,
        'nom': 'Test8',
        'prix': '1 500',
      });
      expect(dish.price, 1500.0);
    });

    test('categorie_id parsé depuis categorie_id', () {
      final dish = Dish.fromJson({
        'id': 18,
        'nom': 'Test9',
        'prix': 500,
        'categorie_id': 7,
      });
      expect(dish.categoryId, 7);
    });
  });
}
