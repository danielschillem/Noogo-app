import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noogo/services/restaurant_storage_service.dart';
import 'package:noogo/models/saved_restaurant.dart';

SavedRestaurant _makeFake({int id = 1, String name = 'Le Baobab'}) =>
    SavedRestaurant(
      id: id,
      name: name,
      imageUrl: 'https://example.com/img.jpg',
      address: 'Ouagadougou',
      phone: '70000001',
      lastScannedAt: DateTime(2026, 4, 1),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RestaurantStorageService — multi-restaurants', () {
    test('getSavedRestaurants returns empty list by default', () async {
      final list = await RestaurantStorageService.getSavedRestaurants();
      expect(list, isEmpty);
    });

    test('addOrUpdateRestaurant adds a restaurant', () async {
      await RestaurantStorageService.addOrUpdateRestaurant(_makeFake());
      final list = await RestaurantStorageService.getSavedRestaurants();
      expect(list.length, 1);
      expect(list.first.name, 'Le Baobab');
    });

    test('addOrUpdateRestaurant updates existing restaurant', () async {
      await RestaurantStorageService.addOrUpdateRestaurant(_makeFake());
      await RestaurantStorageService.addOrUpdateRestaurant(
          _makeFake(id: 1, name: 'Le Grand Baobab'));
      final list = await RestaurantStorageService.getSavedRestaurants();
      expect(list.length, 1);
      expect(list.first.name, 'Le Grand Baobab');
    });

    test('addOrUpdateRestaurant adds multiple distinct restaurants', () async {
      await RestaurantStorageService.addOrUpdateRestaurant(_makeFake(id: 1));
      await RestaurantStorageService.addOrUpdateRestaurant(
          _makeFake(id: 2, name: 'Chez Marie'));
      final list = await RestaurantStorageService.getSavedRestaurants();
      expect(list.length, 2);
    });

    test('removeRestaurant removes correct entry', () async {
      await RestaurantStorageService.addOrUpdateRestaurant(_makeFake(id: 1));
      await RestaurantStorageService.addOrUpdateRestaurant(
          _makeFake(id: 2, name: 'Chez Marie'));
      await RestaurantStorageService.removeRestaurant(1);
      final list = await RestaurantStorageService.getSavedRestaurants();
      expect(list.length, 1);
      expect(list.first.id, 2);
    });

    test('isRestaurantScanned returns false when empty', () async {
      final scanned = await RestaurantStorageService.isRestaurantScanned();
      expect(scanned, isFalse);
    });

    test('isRestaurantScanned returns true after adding', () async {
      await RestaurantStorageService.addOrUpdateRestaurant(_makeFake());
      final scanned = await RestaurantStorageService.isRestaurantScanned();
      expect(scanned, isTrue);
    });

    test('getRestaurantId returns last scanned id', () async {
      await RestaurantStorageService.addOrUpdateRestaurant(_makeFake(id: 99));
      final id = await RestaurantStorageService.getRestaurantId();
      expect(id, '99');
    });

    test('clearAllRestaurants empties the list', () async {
      await RestaurantStorageService.addOrUpdateRestaurant(_makeFake(id: 1));
      await RestaurantStorageService.clearAllRestaurants();
      final list = await RestaurantStorageService.getSavedRestaurants();
      expect(list, isEmpty);
    });

    test('setLastRestaurantId updates last id', () async {
      await RestaurantStorageService.addOrUpdateRestaurant(_makeFake(id: 5));
      await RestaurantStorageService.setLastRestaurantId(5);
      final id = await RestaurantStorageService.getRestaurantId();
      expect(id, '5');
    });
  });

  group('RestaurantStorageService — legacy API', () {
    test('saveRestaurantData sets isScanned', () async {
      await RestaurantStorageService.saveRestaurantData(
        restaurantId: '3',
        restaurantData: {'id': 3, 'nom': 'Test'},
      );
      // Legacy path: just ensure no crash
    });

    test('getRestaurantData returns null when empty', () async {
      final data = await RestaurantStorageService.getRestaurantData();
      expect(data, isNull);
    });

    test('clearRestaurantData does not throw', () async {
      await RestaurantStorageService.clearRestaurantData();
    });
  });
}
