import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/models/saved_restaurant.dart';

void main() {
  group('SavedRestaurant.fromJson / toJson', () {
    final now = DateTime.parse('2026-04-15T12:00:00.000Z');

    test('parse un restaurant sauvegardé complet', () {
      final json = {
        'id': 42,
        'name': 'Restaurant Test',
        'imageUrl': 'https://example.com/img.jpg',
        'address': 'Ouagadougou, Secteur 15',
        'phone': '+22670000001',
        'lastScannedAt': '2026-04-15T12:00:00.000Z',
      };

      final sr = SavedRestaurant.fromJson(json);

      expect(sr.id, 42);
      expect(sr.name, 'Restaurant Test');
      expect(sr.imageUrl, 'https://example.com/img.jpg');
      expect(sr.address, 'Ouagadougou, Secteur 15');
      expect(sr.phone, '+22670000001');
      expect(sr.lastScannedAt.toIso8601String(), startsWith('2026-04-15'));
    });

    test('parse les champs optionnels absents', () {
      final json = {
        'id': 1,
        'name': 'Mini resto',
        'lastScannedAt': '2026-04-15T12:00:00.000Z',
      };

      final sr = SavedRestaurant.fromJson(json);
      expect(sr.imageUrl, isNull);
      expect(sr.address, isNull);
      expect(sr.phone, isNull);
    });

    test('name par défaut "Restaurant" si null dans JSON', () {
      final json = {
        'id': 2,
        'name': null,
        'lastScannedAt': '2026-04-15T12:00:00.000Z',
      };
      final sr = SavedRestaurant.fromJson(json);
      expect(sr.name, 'Restaurant');
    });

    test('lastScannedAt ≈ now si clé absente', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final json = {'id': 3, 'name': 'Test'};
      final sr = SavedRestaurant.fromJson(json);
      expect(sr.lastScannedAt.isAfter(before), true);
    });

    test('lastScannedAt ≈ now si valeur invalide', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final json = {'id': 4, 'name': 'Test', 'lastScannedAt': 'not-a-date'};
      final sr = SavedRestaurant.fromJson(json);
      expect(sr.lastScannedAt.isAfter(before), true);
    });

    test('toJson → fromJson est idempotent (round-trip)', () {
      final original = SavedRestaurant(
        id: 10,
        name: 'La Belle',
        imageUrl: 'https://example.com/img.jpg',
        address: 'Bobo-Dioulasso',
        phone: '+22676000001',
        lastScannedAt: now,
      );

      final restored = SavedRestaurant.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.address, original.address);
      expect(restored.phone, original.phone);
      expect(
        restored.lastScannedAt.toIso8601String(),
        original.lastScannedAt.toIso8601String(),
      );
    });

    test('toJson omet les clés nulles (imageUrl, address, phone)', () {
      final sr = SavedRestaurant(
        id: 5,
        name: 'Sans extras',
        lastScannedAt: now,
      );
      final json = sr.toJson();
      expect(json.containsKey('imageUrl'), false);
      expect(json.containsKey('address'), false);
      expect(json.containsKey('phone'), false);
    });
  });

  group('SavedRestaurant.copyWith', () {
    final base = SavedRestaurant(
      id: 1,
      name: 'Base',
      lastScannedAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
    );

    test('copyWith met à jour lastScannedAt', () {
      final updated = DateTime.parse('2026-04-15T12:00:00.000Z');
      final copy = base.copyWith(lastScannedAt: updated);
      expect(copy.lastScannedAt, updated);
      expect(copy.id, base.id);
      expect(copy.name, base.name);
    });

    test('copyWith conserve lastScannedAt si null passé', () {
      final copy = base.copyWith();
      expect(copy.lastScannedAt, base.lastScannedAt);
    });
  });

  group('SavedRestaurant.listFromJsonString / listToJsonString', () {
    test('serialise et désérialise une liste vide', () {
      final jsonStr = SavedRestaurant.listToJsonString([]);
      final list = SavedRestaurant.listFromJsonString(jsonStr);
      expect(list, isEmpty);
    });

    test('serialise et désérialise une liste de restaurants', () {
      final list = [
        SavedRestaurant(
          id: 1,
          name: 'A',
          lastScannedAt: DateTime.parse('2026-04-01T10:00:00.000Z'),
        ),
        SavedRestaurant(
          id: 2,
          name: 'B',
          address: 'Ouaga',
          lastScannedAt: DateTime.parse('2026-04-02T11:00:00.000Z'),
        ),
      ];

      final jsonStr = SavedRestaurant.listToJsonString(list);
      final restored = SavedRestaurant.listFromJsonString(jsonStr);

      expect(restored.length, 2);
      expect(restored[0].id, 1);
      expect(restored[0].name, 'A');
      expect(restored[1].id, 2);
      expect(restored[1].address, 'Ouaga');
    });
  });
}
