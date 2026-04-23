import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/utils/qr_helper.dart';

void main() {
  const dashboardUrl = 'https://noogo-e5ygx.ondigitalocean.app';

  group('QRHelper.isValidRestaurantQR', () {
    test('retourne true pour une URL de restaurant valide', () {
      expect(
        QRHelper.isValidRestaurantQR('$dashboardUrl/restaurant/42/menu'),
        true,
      );
    });

    test('retourne false pour une URL vide', () {
      expect(QRHelper.isValidRestaurantQR(''), false);
    });

    test('retourne false pour une URL sans /restaurant/', () {
      expect(QRHelper.isValidRestaurantQR('$dashboardUrl/menu/42'), false);
    });

    // La validation est permissive : toute URL contenant /restaurant/ est acceptée
    test('retourne true pour toute URL contenant /restaurant/', () {
      expect(
        QRHelper.isValidRestaurantQR('https://fake.com/restaurant/1/menu'),
        true,
      );
    });

    test('retourne true avec un ID de restaurant avec plusieurs chiffres', () {
      expect(
        QRHelper.isValidRestaurantQR('$dashboardUrl/restaurant/100/menu'),
        true,
      );
    });

    test('retourne true pour un ID numérique direct', () {
      expect(QRHelper.isValidRestaurantQR('42'), true);
    });
  });

  group('QRHelper.parseRestaurantId', () {
    test('extrait l\'ID depuis une URL complète', () {
      expect(
        QRHelper.parseRestaurantId('$dashboardUrl/restaurant/42/menu'),
        42,
      );
    });

    test('extrait un grand ID', () {
      expect(
        QRHelper.parseRestaurantId('$dashboardUrl/restaurant/9999/menu'),
        9999,
      );
    });

    test('retourne null pour une URL sans segment d\'ID', () {
      expect(
        QRHelper.parseRestaurantId('$dashboardUrl/restaurant/menu'),
        null,
      );
    });

    test('retourne null pour une URL vide', () {
      expect(QRHelper.parseRestaurantId(''), null);
    });

    test('retourne null si l\'ID n\'est pas un entier', () {
      expect(
        QRHelper.parseRestaurantId('$dashboardUrl/restaurant/abc/menu'),
        null,
      );
    });
  });

  group('QRHelper.validateAndExtractId', () {
    test('retourne l\'ID pour un QR valide', () {
      expect(
        QRHelper.validateAndExtractId('$dashboardUrl/restaurant/7/menu'),
        7,
      );
    });

    test('retourne null pour un QR sans /restaurant/', () {
      expect(QRHelper.validateAndExtractId('https://autre.com/resto/5'), null);
    });
  });

  group('QRHelper.generateRestaurantQRData', () {
    test('génère l\'URL correcte pour un restaurant', () {
      // Génère une URL valide avec /restaurant/
      final url = QRHelper.generateRestaurantQRData(3);
      expect(url.contains('/restaurant/3'), true);
      expect(QRHelper.isValidRestaurantQR(url), true);
    });
  });

  group('QRHelper.getMenuUrl', () {
    test('construit une URL valide pour le restaurant', () {
      final url = QRHelper.getMenuUrl(12);
      expect(url.contains('/restaurant/12'), true);
      expect(QRHelper.isValidRestaurantQR(url), true);
    });
  });
}
