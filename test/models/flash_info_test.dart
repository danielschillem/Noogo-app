import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:noogo/models/flash_info.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(
      fileName: 'assets/env/.env',
      isOptional: true,
      mergeWith: {
        'API_BASE_URL': 'http://localhost/api',
        'ENVIRONMENT': 'test',
      },
    );
  });

  group('FlashInfo.fromJson', () {
    test('parse une offre flash complète', () {
      final json = {
        'id': 1,
        'name': 'Promo Ramadan',
        'description': '-20% sur tous les plats',
        'validity_period': '7 jours',
        'discount_type': 'percentage',
        'discount_value': '20',
        'conditions': 'Valable le soir uniquement',
        'expiry_date': '2026-04-30T00:00:00.000Z',
        'image': 'storage/flash/promo.jpg',
        'background_color': '#FF6B6B',
        'button_text': 'En profiter',
      };

      final fi = FlashInfo.fromJson(json);

      expect(fi.id, 1);
      expect(fi.name, 'Promo Ramadan');
      expect(fi.description, '-20% sur tous les plats');
      expect(fi.validityPeriod, '7 jours');
      expect(fi.discountType, 'percentage');
      expect(fi.discountValue, '20');
      expect(fi.conditions, 'Valable le soir uniquement');
      expect(fi.expiryDate, isNotNull);
      expect(fi.imageUrl, contains('promo.jpg'));
      expect(fi.backgroundColor, '#FF6B6B');
      expect(fi.buttonText, 'En profiter');
    });

    test('parse les champs optionnels absents', () {
      final json = {
        'id': 2,
        'name': 'Offre simple',
        'description': 'Description simple',
        'image': null,
      };

      final fi = FlashInfo.fromJson(json);

      expect(fi.id, 2);
      expect(fi.name, 'Offre simple');
      expect(fi.validityPeriod, isNull);
      expect(fi.discountType, isNull);
      expect(fi.discountValue, isNull);
      expect(fi.conditions, isNull);
      expect(fi.expiryDate, isNull);
      expect(fi.imageUrl, isEmpty);
      expect(fi.backgroundColor, '#FF6B6B'); // valeur par défaut
      expect(fi.buttonText, 'Profiter de l\'offre'); // valeur par défaut
    });

    test('utilise URL absolue si image commence par http', () {
      final json = {
        'id': 3,
        'name': 'Test',
        'description': 'Desc',
        'image': 'https://cdn.example.com/promo.jpg',
      };

      final fi = FlashInfo.fromJson(json);
      expect(fi.imageUrl, 'https://cdn.example.com/promo.jpg');
    });

    test('construit URL complète si image est un chemin relatif', () {
      final json = {
        'id': 4,
        'name': 'Test',
        'description': 'Desc',
        'image': 'flash/offre.jpg',
      };

      final fi = FlashInfo.fromJson(json);
      expect(fi.imageUrl, contains('flash/offre.jpg'));
      expect(fi.imageUrl, startsWith('https://'));
    });

    test('expiry_date null si date invalide', () {
      final json = {
        'id': 5,
        'name': 'Test',
        'description': 'Desc',
        'expiry_date': 'not-a-date',
        'image': null,
      };

      final fi = FlashInfo.fromJson(json);
      expect(fi.expiryDate, isNull);
    });

    test('discount_value null si manquant', () {
      final json = {
        'id': 6,
        'name': 'Test',
        'description': 'Desc',
        'discount_value': null,
        'image': null,
      };

      final fi = FlashInfo.fromJson(json);
      expect(fi.discountValue, isNull);
    });

    test('discount_value converti en string depuis int', () {
      final json = {
        'id': 7,
        'name': 'Test',
        'description': 'Desc',
        'discount_value': 15,
        'image': null,
      };

      final fi = FlashInfo.fromJson(json);
      expect(fi.discountValue, '15');
    });
  });

  group('FlashInfo.toJson', () {
    test('convertit en JSON sérialisable', () {
      final fi = FlashInfo(
        id: 1,
        name: 'Offre test',
        description: 'Description',
        imageUrl: 'https://example.com/img.jpg',
        backgroundColor: '#FF0000',
        buttonText: 'Cliquez ici',
        discountType: 'fixed',
        discountValue: '500',
      );

      final json = fi.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Offre test');
      expect(json['background_color'], '#FF0000');
      expect(json['discount_value'], '500');
    });
  });
}
