import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:noogo/models/restaurant.dart';

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

  group('Restaurant.fromJson', () {
    test('parse un restaurant complet depuis JSON', () {
      final json = {
        'id': 1,
        'nom': 'Le Bon Coin',
        'telephone': '+22670000001',
        'adresse': 'Ouagadougou, Burkina Faso',
        'email': 'contact@leboncoin.bf',
        'logo': 'storage/logos/leboncoin.jpg',
        'description': 'Restaurant traditionnel',
        'heures_ouverture': '08:00-22:00',
        'user_id': 5,
        'images': ['storage/photos/img1.jpg', 'storage/photos/img2.jpg'],
        'is_open': true,
        'latitude': 12.3456,
        'longitude': -1.5432,
      };

      final r = Restaurant.fromJson(json);

      expect(r.id, 1);
      expect(r.nom, 'Le Bon Coin');
      expect(r.telephone, '+22670000001');
      expect(r.adresse, 'Ouagadougou, Burkina Faso');
      expect(r.email, 'contact@leboncoin.bf');
      expect(r.logo, 'storage/logos/leboncoin.jpg');
      expect(r.description, 'Restaurant traditionnel');
      expect(r.heuresOuverture, '08:00-22:00');
      expect(r.userId, 5);
      expect(r.images, ['storage/photos/img1.jpg', 'storage/photos/img2.jpg']);
      expect(r.isOpenFromApi, true);
      expect(r.latitude, 12.3456);
      expect(r.longitude, -1.5432);
    });

    test('parse les champs optionnels absents sans erreur', () {
      final json = {
        'id': 2,
        'nom': 'Chez Mamie',
        'telephone': '0000002',
        'adresse': 'Bobo-Dioulasso',
      };

      final r = Restaurant.fromJson(json);

      expect(r.id, 2);
      expect(r.email, isNull);
      expect(r.logo, isNull);
      expect(r.description, isNull);
      expect(r.heuresOuverture, isNull);
      expect(r.userId, isNull);
      expect(r.images, isEmpty);
      expect(r.isOpenFromApi, isNull);
      expect(r.latitude, isNull);
      expect(r.longitude, isNull);
    });

    test('parse is_open depuis entier (0/1)', () {
      final r1 = Restaurant.fromJson({
        'id': 3,
        'nom': 'A',
        'telephone': '0',
        'adresse': 'X',
        'is_open': 1,
      });
      final r2 = Restaurant.fromJson({
        'id': 4,
        'nom': 'B',
        'telephone': '0',
        'adresse': 'Y',
        'is_open': 0,
      });

      expect(r1.isOpenFromApi, true);
      expect(r2.isOpenFromApi, false);
    });

    test('parse is_open depuis string "true"/"false"', () {
      final r1 = Restaurant.fromJson({
        'id': 5,
        'nom': 'C',
        'telephone': '0',
        'adresse': 'Z',
        'is_open': 'true',
      });
      final r2 = Restaurant.fromJson({
        'id': 6,
        'nom': 'D',
        'telephone': '0',
        'adresse': 'W',
        'is_open': 'false',
      });

      expect(r1.isOpenFromApi, true);
      expect(r2.isOpenFromApi, false);
    });

    test('parse latitude/longitude depuis string', () {
      final r = Restaurant.fromJson({
        'id': 7,
        'nom': 'E',
        'telephone': '0',
        'adresse': 'X',
        'latitude': '12.5',
        'longitude': '-1.5',
      });
      expect(r.latitude, 12.5);
      expect(r.longitude, -1.5);
    });

    test('parse latitude/longitude depuis int', () {
      final r = Restaurant.fromJson({
        'id': 8,
        'nom': 'F',
        'telephone': '0',
        'adresse': 'X',
        'latitude': 12,
        'longitude': -1,
      });
      expect(r.latitude, 12.0);
      expect(r.longitude, -1.0);
    });

    test('parse les images depuis une liste', () {
      final r = Restaurant.fromJson({
        'id': 9,
        'nom': 'G',
        'telephone': '0',
        'adresse': 'X',
        'images': ['img1.jpg', 'img2.jpg', 'img3.jpg'],
      });
      expect(r.images.length, 3);
      expect(r.images, contains('img1.jpg'));
    });

    test('parse les images depuis une chaîne JSON sérialisée', () {
      final r = Restaurant.fromJson({
        'id': 10,
        'nom': 'H',
        'telephone': '0',
        'adresse': 'X',
        'images': '["img1.jpg","img2.jpg"]',
      });
      expect(r.images.length, 2);
    });

    test('retourne liste vide si images est une Map (objet invalide)', () {
      final r = Restaurant.fromJson({
        'id': 11,
        'nom': 'I',
        'telephone': '0',
        'adresse': 'X',
        'images': {'key': 'value'},
      });
      expect(r.images, isEmpty);
    });

    test('retourne liste vide si images est null', () {
      final r = Restaurant.fromJson({
        'id': 12,
        'nom': 'J',
        'telephone': '0',
        'adresse': 'X',
        'images': null,
      });
      expect(r.images, isEmpty);
    });
  });

  group('Restaurant.isOpen getter', () {
    test('retourne isOpenFromApi si défini à true', () {
      final r = Restaurant.fromJson({
        'id': 1, 'nom': 'A', 'telephone': '0', 'adresse': 'X',
        'is_open': true,
        'heures_ouverture': '00:00-00:00', // horaires fermés, ignorés
      });
      expect(r.isOpen, true);
    });

    test('retourne isOpenFromApi si défini à false', () {
      final r = Restaurant.fromJson({
        'id': 2, 'nom': 'B', 'telephone': '0', 'adresse': 'X',
        'is_open': false,
        'heures_ouverture': '00:00-23:59', // horaires ouverts, ignorés
      });
      expect(r.isOpen, false);
    });

    test('retourne false si pas d\'horaires et is_open null', () {
      final r = Restaurant(
        id: 3,
        nom: 'C',
        telephone: '0',
        adresse: 'X',
      );
      expect(r.isOpen, false);
    });

    test('calcule l\'ouverture depuis les horaires si is_open null', () {
      // Test avec des plages toujours ouvertes (00:00-23:59)
      final r = Restaurant(
        id: 4,
        nom: 'D',
        telephone: '0',
        adresse: 'X',
        heuresOuverture: '00:00-23:59',
      );
      expect(r.isOpen, true);
    });

    test('retourne false pour des horaires invalides', () {
      final r = Restaurant(
        id: 5,
        nom: 'E',
        telephone: '0',
        adresse: 'X',
        heuresOuverture: 'invalide',
      );
      expect(r.isOpen, false);
    });
  });

  group('Restaurant.formattedOpeningHours', () {
    test('retourne texte par défaut si heures null', () {
      final r = Restaurant(
        id: 1,
        nom: 'A',
        telephone: '0',
        adresse: 'X',
      );
      expect(r.formattedOpeningHours, 'Horaires non définis');
    });

    test('retourne texte par défaut si heures vide', () {
      final r = Restaurant(
        id: 2,
        nom: 'B',
        telephone: '0',
        adresse: 'X',
        heuresOuverture: '',
      );
      expect(r.formattedOpeningHours, 'Horaires non définis');
    });

    test('formate horaires simples 08:00-22:00', () {
      final r = Restaurant(
        id: 3,
        nom: 'C',
        telephone: '0',
        adresse: 'X',
        heuresOuverture: '08:00-22:00',
      );
      expect(r.formattedOpeningHours, isNotEmpty);
    });
  });

  group('Restaurant.toJson', () {
    test('convertit un restaurant en JSON', () {
      final r = Restaurant(
        id: 1,
        nom: 'Le Bon Coin',
        telephone: '+22670000001',
        adresse: 'Ouagadougou',
        email: 'contact@test.bf',
        isOpenFromApi: true,
      );
      final json = r.toJson();
      expect(json['id'], 1);
      expect(json['nom'], 'Le Bon Coin');
      expect(json['is_open'], true);
    });
  });

  group('Restaurant — horaires multi-plages', () {
    test('ouvert sur plage multiple (matin + soir)', () {
      final r = Restaurant(
        id: 1,
        nom: 'A',
        telephone: '0',
        adresse: 'X',
        heuresOuverture: '00:00-23:59,06:00-12:00',
      );
      expect(r.isOpen, true);
    });

    test('horaires avec format invalide ne plante pas', () {
      final r = Restaurant(
        id: 2,
        nom: 'B',
        telephone: '0',
        adresse: 'X',
        heuresOuverture: 'malformed-data',
      );
      expect(r.isOpen, isFalse);
    });

    test('horaires fermés 01:00-02:00 — restaurant probablement fermé', () {
      final r = Restaurant(
        id: 3,
        nom: 'C',
        telephone: '0',
        adresse: 'X',
        heuresOuverture: '01:00-02:00',
      );
      // Soit ouvert soit fermé selon l'heure — ne plante pas
      expect(r.isOpen, isA<bool>());
    });

    test('horaire après minuit 22:00-02:00', () {
      final r = Restaurant(
        id: 4,
        nom: 'D',
        telephone: '0',
        adresse: 'X',
        heuresOuverture: '22:00-02:00',
      );
      expect(r.isOpen, isA<bool>());
    });
  });

  group('Restaurant — getters de compatibilité', () {
    test('nom getter retourne le nom', () {
      final r = Restaurant(id: 1, nom: 'Test', telephone: '0', adresse: 'X');
      expect(r.nom, 'Test');
    });

    test('telephone getter retourne le téléphone', () {
      final r =
          Restaurant(id: 1, nom: 'A', telephone: '70000000', adresse: 'X');
      expect(r.telephone, '70000000');
    });

    test('images vide par défaut', () {
      final r = Restaurant(id: 1, nom: 'A', telephone: '0', adresse: 'X');
      expect(r.images, isEmpty);
    });

    test('latitude et longitude nulls par défaut', () {
      final r = Restaurant(id: 1, nom: 'A', telephone: '0', adresse: 'X');
      expect(r.latitude, isNull);
      expect(r.longitude, isNull);
    });

    test('description non nulle si fournie', () {
      final r = Restaurant(
        id: 1,
        nom: 'A',
        telephone: '0',
        adresse: 'X',
        description: 'Un bon resto',
      );
      expect(r.description, 'Un bon resto');
    });

    test('email non nul si fourni', () {
      final r = Restaurant(
        id: 1,
        nom: 'A',
        telephone: '0',
        adresse: 'X',
        email: 'test@test.com',
      );
      expect(r.email, 'test@test.com');
    });

    test('logo non nul si fourni', () {
      final r = Restaurant(
        id: 1,
        nom: 'A',
        telephone: '0',
        adresse: 'X',
        logo: 'storage/logo.png',
      );
      expect(r.logo, 'storage/logo.png');
    });

    test('userId nul par défaut', () {
      final r = Restaurant(id: 1, nom: 'A', telephone: '0', adresse: 'X');
      expect(r.userId, isNull);
    });
  });

  group('Restaurant.fromJson — cas limites', () {
    test('id depuis string', () {
      final r = Restaurant.fromJson({
        'id': '42',
        'nom': 'A',
        'telephone': '0',
        'adresse': 'X',
      });
      expect(r.id, 42);
    });

    test('id depuis double', () {
      final r = Restaurant.fromJson({
        'id': 1.0,
        'nom': 'A',
        'telephone': '0',
        'adresse': 'X',
      });
      expect(r.id, 1);
    });

    test('images depuis string JSON sérialisée', () {
      final r = Restaurant.fromJson({
        'id': 1,
        'nom': 'A',
        'telephone': '0',
        'adresse': 'X',
        'images': '["photo1.jpg","photo2.jpg"]',
      });
      expect(r.images.length, 2);
    });

    test('images string simple (non JSON)', () {
      final r = Restaurant.fromJson({
        'id': 1,
        'nom': 'A',
        'telephone': '0',
        'adresse': 'X',
        'images': 'photo.jpg',
      });
      expect(r.images, isNotEmpty);
    });

    test('is_open depuis string "1"', () {
      final r = Restaurant.fromJson({
        'id': 1,
        'nom': 'A',
        'telephone': '0',
        'adresse': 'X',
        'is_open': '1',
      });
      expect(r.isOpenFromApi, true);
    });
  });
}
