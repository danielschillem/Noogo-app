import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/models/dish.dart';

// Reproduit la logique de filtrage du MenuScreen._buildDishesSection
List<Dish> filterDishes(List<Dish> dishes, String query) {
  if (query.isEmpty) return dishes;
  final q = query.toLowerCase();
  return dishes.where((dish) {
    return dish.name.toLowerCase().contains(q) ||
        dish.description.toLowerCase().contains(q);
  }).toList();
}

Dish _makeDish({
  required int id,
  required String name,
  String description = '',
  int categoryId = 1,
}) =>
    Dish(
      id: id,
      name: name,
      description: description,
      price: 1500,
      imageUrl: '',
      categoryId: categoryId,
      category: 'Test',
      isAvailable: true,
    );

void main() {
  final dishes = [
    _makeDish(
        id: 1, name: 'Riz sauce tomate', description: 'Délicieux riz maison'),
    _makeDish(
        id: 2, name: 'Poulet braisé', description: 'Poulet grillé aux épices'),
    _makeDish(id: 3, name: 'Salade verte', description: 'Fraîche et légère'),
    _makeDish(
        id: 4, name: 'Jus de bissap', description: 'Boisson locale naturelle'),
    _makeDish(id: 5, name: 'Burger poulet', description: 'Burger croustillant'),
  ];

  group('filterDishes - recherche par nom', () {
    test('retourne tous les plats si requête vide', () {
      expect(filterDishes(dishes, ''), dishes);
    });

    test('filtre par nom exact (casse insensible)', () {
      final results = filterDishes(dishes, 'riz');
      expect(results.length, 1);
      expect(results.first.name, 'Riz sauce tomate');
    });

    test('filtre par nom en majuscules', () {
      final results = filterDishes(dishes, 'POULET');
      expect(results.length, 2); // Poulet braisé + Burger poulet
    });

    test('filtre par mot partiel', () {
      final results = filterDishes(dishes, 'bra');
      expect(results.length, 1);
      expect(results.first.name, 'Poulet braisé');
    });

    test('retourne liste vide si aucune correspondance', () {
      final results = filterDishes(dishes, 'pizza');
      expect(results, isEmpty);
    });
  });

  group('filterDishes - recherche par description', () {
    test('trouve un plat via sa description', () {
      final results = filterDishes(dishes, 'locale');
      expect(results.length, 1);
      expect(results.first.name, 'Jus de bissap');
    });

    test('trouve via description avec casse mixte', () {
      final results = filterDishes(dishes, 'ÉPICES');
      expect(results.length, 1);
      expect(results.first.name, 'Poulet braisé');
    });

    test('matche à la fois nom et description', () {
      // "poulet" est dans le nom de deux plats et la description d'un autre
      final results = filterDishes(dishes, 'poulet');
      // Poulet braisé, Burger poulet
      expect(results.length, 2);
    });
  });

  group('filterDishes - cas limites', () {
    test('recherche avec espace fonctionne', () {
      final results = filterDishes(dishes, 'sauce tomate');
      expect(results.length, 1);
    });

    test('retourne liste vide sur liste vide', () {
      expect(filterDishes([], 'riz'), isEmpty);
    });

    test('requête = caractère unique', () {
      final results = filterDishes(dishes, 'j');
      expect(results.isNotEmpty, true); // "Jus de bissap"
    });
  });
}
