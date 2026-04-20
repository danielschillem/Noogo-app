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

  group('FlashInfo.isValid', () {
    test('isValid true si expiryDate null', () {
      final fi = FlashInfo(id: 1, name: 'X', description: '', imageUrl: '');
      expect(fi.isValid, isTrue);
    });

    test('isValid true si expiryDate dans le futur', () {
      final fi = FlashInfo(
        id: 2,
        name: 'X',
        description: '',
        imageUrl: '',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(fi.isValid, isTrue);
    });

    test('isValid false si expiryDate dans le passé', () {
      final fi = FlashInfo(
        id: 3,
        name: 'X',
        description: '',
        imageUrl: '',
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(fi.isValid, isFalse);
    });
  });

  group('FlashInfo.formattedExpiryDate', () {
    test('retourne "Sans limite de temps" si pas de date', () {
      final fi = FlashInfo(id: 1, name: 'X', description: '', imageUrl: '');
      expect(fi.formattedExpiryDate, 'Sans limite de temps');
    });

    test('retourne "Expire aujourd\'hui" si même jour', () {
      final fi = FlashInfo(
        id: 2,
        name: 'X',
        description: '',
        imageUrl: '',
        expiryDate: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(fi.formattedExpiryDate, contains('aujourd'));
    });

    test('retourne "Expire dans X jours" si < 7 jours', () {
      final fi = FlashInfo(
        id: 3,
        name: 'X',
        description: '',
        imageUrl: '',
        expiryDate: DateTime.now().add(const Duration(days: 3)),
      );
      expect(fi.formattedExpiryDate, contains('3'));
    });

    test('retourne date formatée si >= 7 jours', () {
      final fi = FlashInfo(
        id: 4,
        name: 'X',
        description: '',
        imageUrl: '',
        expiryDate: DateTime(2030, 12, 31),
      );
      expect(fi.formattedExpiryDate, contains('2030'));
    });
  });

  group('FlashInfo.formattedDiscount', () {
    test('retourne description si pas de discountValue', () {
      final fi = FlashInfo(
          id: 1, name: 'X', description: 'Promo spéciale', imageUrl: '');
      expect(fi.formattedDiscount, 'Promo spéciale');
    });

    test('retourne "-%%" si type pourcentage', () {
      final fi = FlashInfo(
        id: 2,
        name: 'X',
        description: 'Desc',
        imageUrl: '',
        discountType: 'percentage',
        discountValue: '15',
      );
      expect(fi.formattedDiscount, '-15%');
    });

    test('retourne "-X FCFA" si type fixe', () {
      final fi = FlashInfo(
        id: 3,
        name: 'X',
        description: 'Desc',
        imageUrl: '',
        discountType: 'fixed',
        discountValue: '500',
      );
      expect(fi.formattedDiscount, '-500 FCFA');
    });

    test('retourne description si discountValue vide', () {
      final fi = FlashInfo(
        id: 4,
        name: 'X',
        description: 'Desc alt',
        imageUrl: '',
        discountValue: '',
      );
      expect(fi.formattedDiscount, 'Desc alt');
    });
  });

  group('FlashInfo.discountBadge', () {
    test('badge "-X%" pour type pourcentage', () {
      final fi = FlashInfo(
        id: 1,
        name: 'X',
        description: 'Desc',
        imageUrl: '',
        discountType: 'pourcentage',
        discountValue: '20',
      );
      expect(fi.discountBadge, '-20%');
    });

    test('badge "-X FCFA" pour type fixe', () {
      final fi = FlashInfo(
        id: 2,
        name: 'X',
        description: 'Desc',
        imageUrl: '',
        discountType: 'fixe',
        discountValue: '300',
      );
      expect(fi.discountBadge, '-300 FCFA');
    });

    test('badge utilise description courte si pas de discount', () {
      final fi = FlashInfo(
        id: 3,
        name: 'X',
        description: 'Court',
        imageUrl: '',
      );
      expect(fi.discountBadge, 'Court');
    });

    test('title getter retourne le nom', () {
      final fi =
          FlashInfo(id: 4, name: 'Mon Titre', description: '', imageUrl: '');
      expect(fi.title, 'Mon Titre');
    });
  });
}
