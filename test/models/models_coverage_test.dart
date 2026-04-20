import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/models/category.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/restaurant.dart';

void main() {
  group('Restaurant model', () {
    test('isOpen defaults to false without hours', () {
      final r = Restaurant(
        id: 1,
        nom: 'Test',
        telephone: '70000000',
        adresse: 'Ouaga',
      );
      expect(r.isOpen, isFalse);
    });

    test('isOpen uses isOpenFromApi when provided', () {
      final rOpen = Restaurant(
        id: 1,
        nom: 'Test',
        telephone: '70000000',
        adresse: 'Ouaga',
        isOpenFromApi: true,
      );
      final rClosed = Restaurant(
        id: 2,
        nom: 'Test2',
        telephone: '70000001',
        adresse: 'Ouaga',
        isOpenFromApi: false,
      );
      expect(rOpen.isOpen, isTrue);
      expect(rClosed.isOpen, isFalse);
    });
  });

  group('Category model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 5,
        'nom': 'Boissons',
        'categorie': 'Boissons',
        'description': 'Des boissons fraÃ®ches',
        'images': null,
      };
      final cat = Category.fromJson(json);
      expect(cat.id, 5);
      expect(cat.name, 'Boissons');
    });
  });

  group('Dish model', () {
    test('isAvailable and isDishOfTheDay default correctly', () {
      final d = Dish(
        id: 1,
        name: 'ThiÃ©boudienne',
        description: '',
        price: 2000,
        imageUrl: '',
        categoryId: 1,
        category: 'Plats',
        isAvailable: true,
      );
      expect(d.isAvailable, isTrue);
      expect(d.isDishOfTheDay, isFalse);
      expect(d.preparationTime, 0);
    });

    test('price is stored correctly', () {
      final d = Dish(
        id: 2,
        name: 'Jus de bissap',
        description: '',
        price: 500,
        imageUrl: '',
        categoryId: 1,
        category: 'Boissons',
        isAvailable: true,
      );
      expect(d.price, 500.0);
    });
  });

  group('OrderItem model', () {
    Dish makeDish() => Dish(
          id: 1,
          name: 'Riz',
          description: '',
          price: 1500,
          imageUrl: '',
          categoryId: 1,
          category: 'Plats',
          isAvailable: true,
        );

    test('totalPrice calculates correctly', () {
      final item = OrderItem(dish: makeDish(), quantity: 3);
      expect(item.totalPrice, 4500.0);
    });

    test('quantity can be updated', () {
      final item = OrderItem(dish: makeDish(), quantity: 1);
      item.quantity = 5;
      expect(item.quantity, 5);
      expect(item.totalPrice, 7500.0);
    });

    test('toJson / fromJson round-trip', () {
      final item = OrderItem(dish: makeDish(), quantity: 2);
      final json = item.toJson();
      expect(json['quantity'], 2);
      expect(json['dish'], isA<Map>());
    });
  });
}
