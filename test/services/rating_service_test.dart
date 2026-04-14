import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noogo/services/rating_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RatingService', () {
    test('loadRatings retourne vide initialement', () async {
      final ratings = await RatingService.loadRatings();
      expect(ratings, isEmpty);
    });

    test('saveRating persiste étoiles et commentaire', () async {
      await RatingService.saveRating(1, 5, 'Excellent !');
      final rating = await RatingService.getRating(1);
      expect(rating, isNotNull);
      expect(rating!['stars'], 5);
      expect(rating['comment'], 'Excellent !');
    });

    test('saveRating avec commentaire null utilise le string vide', () async {
      await RatingService.saveRating(2, 3, null);
      final rating = await RatingService.getRating(2);
      expect(rating!['comment'], '');
    });

    test('hasRated retourne false si non noté', () async {
      final result = await RatingService.hasRated(99);
      expect(result, isFalse);
    });

    test('hasRated retourne true après saveRating', () async {
      await RatingService.saveRating(10, 4, 'Bien');
      final result = await RatingService.hasRated(10);
      expect(result, isTrue);
    });

    test('loadRatedOrderIds retourne les IDs notés', () async {
      await RatingService.saveRating(1, 5, '');
      await RatingService.saveRating(2, 3, '');
      final ids = await RatingService.loadRatedOrderIds();
      expect(ids, containsAll([1, 2]));
    });

    test('getRating retourne null pour une commande non notée', () async {
      final rating = await RatingService.getRating(42);
      expect(rating, isNull);
    });

    test('saveRating écrase une note existante', () async {
      await RatingService.saveRating(5, 2, 'Mauvais');
      await RatingService.saveRating(5, 5, 'Finalement super !');
      final rating = await RatingService.getRating(5);
      expect(rating!['stars'], 5);
      expect(rating['comment'], 'Finalement super !');
    });

    test('saveRating contient un champ date', () async {
      await RatingService.saveRating(7, 4, 'Ok');
      final rating = await RatingService.getRating(7);
      expect(rating!['date'], isA<String>());
      expect(rating['date'], isNotEmpty);
    });

    test('plusieurs commandes indépendantes', () async {
      await RatingService.saveRating(11, 1, 'Nul');
      await RatingService.saveRating(12, 5, 'Super');
      expect((await RatingService.getRating(11))!['stars'], 1);
      expect((await RatingService.getRating(12))!['stars'], 5);
    });
  });
}
