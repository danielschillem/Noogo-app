import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noogo/services/favorites_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FavoritesService', () {
    test('loadFavorites retourne un set vide initialement', () async {
      final ids = await FavoritesService.loadFavorites();
      expect(ids, isEmpty);
    });

    test('addFavorite ajoute un ID', () async {
      final ids = await FavoritesService.addFavorite(42);
      expect(ids, contains(42));
    });

    test('addFavorite est idempotent (double ajout)', () async {
      await FavoritesService.addFavorite(10);
      final ids = await FavoritesService.addFavorite(10);
      expect(ids.where((id) => id == 10).length, 1);
    });

    test('removeFavorite retire un ID', () async {
      await FavoritesService.addFavorite(7);
      final ids = await FavoritesService.removeFavorite(7);
      expect(ids, isNot(contains(7)));
    });

    test('removeFavorite ne plante pas si ID absent', () async {
      final ids = await FavoritesService.removeFavorite(999);
      expect(ids, isEmpty);
    });

    test('toggleFavorite ajoute si absent', () async {
      final ids = await FavoritesService.toggleFavorite(5);
      expect(ids, contains(5));
    });

    test('toggleFavorite retire si présent', () async {
      await FavoritesService.addFavorite(5);
      final ids = await FavoritesService.toggleFavorite(5);
      expect(ids, isNot(contains(5)));
    });

    test('clearAll vide tous les favoris', () async {
      await FavoritesService.addFavorite(1);
      await FavoritesService.addFavorite(2);
      await FavoritesService.clearAll();
      final ids = await FavoritesService.loadFavorites();
      expect(ids, isEmpty);
    });

    test('persistance entre appels (SharedPreferences mock)', () async {
      await FavoritesService.addFavorite(100);
      await FavoritesService.addFavorite(200);
      final ids = await FavoritesService.loadFavorites();
      expect(ids, containsAll([100, 200]));
    });
  });
}
