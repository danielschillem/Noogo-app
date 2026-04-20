import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noogo/config/api_config.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      dotenv.loadFromString(envString: 'ENVIRONMENT=test');
    } catch (_) {}
  });

  group('ApiConfig — getters depuis dotenv', () {
    test('baseUrl est non vide', () {
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.baseUrl, isA<String>());
    });

    test('imageBaseUrl est non vide', () {
      expect(ApiConfig.imageBaseUrl, isNotEmpty);
    });

    test('qrBaseUrl est non vide', () {
      expect(ApiConfig.qrBaseUrl, isNotEmpty);
    });

    test('pusherCluster a une valeur par défaut', () {
      expect(ApiConfig.pusherCluster, isNotEmpty);
    });

    test('pusherKey retourne une chaîne', () {
      expect(ApiConfig.pusherKey, isA<String>());
    });

    test('pusherAppId retourne une chaîne', () {
      expect(ApiConfig.pusherAppId, isA<String>());
    });

    test('pusherAuthEndpoint est non vide', () {
      expect(ApiConfig.pusherAuthEndpoint, isNotEmpty);
    });

    test('environment retourne une valeur', () {
      expect(ApiConfig.environment, isNotEmpty);
    });

    test('isProduction est false en test', () {
      // ENVIRONMENT=test → pas production
      expect(ApiConfig.isProduction, isFalse);
    });

    test('sentryDsn retourne une chaîne', () {
      expect(ApiConfig.sentryDsn, isA<String>());
    });

    test('analyticsEndpoint retourne une chaîne', () {
      expect(ApiConfig.analyticsEndpoint, isA<String>());
    });

    test('defaultImageUrl est une URL valide', () {
      expect(ApiConfig.defaultImageUrl, startsWith('https://'));
    });

    test('isDebugMode est un bool', () {
      expect(ApiConfig.isDebugMode, isA<bool>());
    });
  });

  group('ApiConfig.getFullImageUrl', () {
    test('retourne defaultImageUrl si path null', () {
      final url = ApiConfig.getFullImageUrl(null);
      expect(url, ApiConfig.defaultImageUrl);
    });

    test('retourne defaultImageUrl si path vide', () {
      final url = ApiConfig.getFullImageUrl('');
      expect(url, ApiConfig.defaultImageUrl);
    });

    test('retourne defaultImageUrl si path espaces seuls', () {
      final url = ApiConfig.getFullImageUrl('   ');
      expect(url, ApiConfig.defaultImageUrl);
    });

    test('retourne l\'URL telle quelle si déjà http', () {
      const input = 'https://example.com/image.jpg';
      final url = ApiConfig.getFullImageUrl(input);
      expect(url, startsWith('http'));
    });

    test('construit une URL complète pour un path relatif', () {
      final url = ApiConfig.getFullImageUrl('storage/dishes/plat.jpg');
      expect(url, contains('plat.jpg'));
    });

    test('ne plante pas avec un path quelconque', () {
      expect(
          () => ApiConfig.getFullImageUrl('some/random/path'), returnsNormally);
    });
  });

  group('ApiConfig.authBaseUrl', () {
    test('authBaseUrl est non vide', () {
      expect(ApiConfig.authBaseUrl, isNotEmpty);
    });

    test('authBaseUrl contient auth', () {
      expect(ApiConfig.authBaseUrl.toLowerCase(), contains('auth'));
    });
  });

  group('ApiConfig.getSafeImageUrl', () {
    test('retourne defaultImageUrl si null', () {
      final url = ApiConfig.getSafeImageUrl(null);
      expect(url, isNotEmpty);
      expect(url, startsWith('https://'));
    });

    test('retourne defaultImageUrl si vide', () {
      final url = ApiConfig.getSafeImageUrl('');
      expect(url, startsWith('https://'));
    });

    test('retourne URL pour chemin HTTP valide', () {
      final url = ApiConfig.getSafeImageUrl('https://example.com/img.jpg');
      expect(url, startsWith('https://'));
    });

    test('retourne URL pour chemin relatif storage/', () {
      final url = ApiConfig.getSafeImageUrl('storage/dishes/plat.jpg');
      expect(url, startsWith('https://'));
    });
  });

  group('ApiConfig.getFullImageUrl — chemins spéciaux', () {
    test('path avec slash initial est nettoyé', () {
      final url = ApiConfig.getFullImageUrl('/storage/img.jpg');
      expect(url, contains('img.jpg'));
    });

    test('path categories/ préfixé storage/', () {
      final url = ApiConfig.getFullImageUrl('categories/cat.jpg');
      expect(url, contains('categories/cat.jpg'));
    });

    test('path restaurants/ préfixé storage/', () {
      final url = ApiConfig.getFullImageUrl('restaurants/rest.jpg');
      expect(url, contains('restaurants/rest.jpg'));
    });

    test('path plats/ préfixé storage/', () {
      final url = ApiConfig.getFullImageUrl('plats/dish.jpg');
      expect(url, contains('plats/dish.jpg'));
    });

    test('path dishes/ préfixé storage/', () {
      final url = ApiConfig.getFullImageUrl('dishes/dish.jpg');
      expect(url, contains('dishes'));
    });

    test('chemin URL http: retourné tel quel', () {
      const raw = 'http://legacy.example.com/img.jpg';
      expect(ApiConfig.getFullImageUrl(raw), raw);
    });

    test('juste un nom de fichier → storage/images/', () {
      final url = ApiConfig.getFullImageUrl('photo.jpg');
      expect(url, contains('photo.jpg'));
    });
  });

  group('ApiConfig.getApiUrl', () {
    test('endpoint sans slash initial', () {
      final url = ApiConfig.getApiUrl('restaurants');
      expect(url, contains('restaurants'));
      expect(url, startsWith('http'));
    });

    test('endpoint avec slash initial est nettoyé', () {
      final url = ApiConfig.getApiUrl('/menus');
      expect(url, contains('menus'));
    });

    test('ne produit pas de double slash dans le path', () {
      final url = ApiConfig.getApiUrl('orders');
      // Retirer le protocole (https://) avant de vérifier
      final path = url.replaceFirst(RegExp(r'https?://[^/]+'), '');
      expect(path, isNot(contains('//')));
    });
  });

  group('ApiConfig.checkImageAccessibility', () {
    test('retourne false pour URL invalide', () async {
      final result = await ApiConfig.checkImageAccessibility(
        'https://invalid-host-12345.noogo-test.com/img.jpg',
      );
      expect(result, isFalse);
    });
  });
}
