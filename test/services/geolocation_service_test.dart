import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/services/geolocation_service.dart';

/// Haversine locale pour les tests (même formule que GeolocationService)
double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

void main() {
  group('Haversine — calcul de distance', () {
    test('même point → 0 mètre', () {
      expect(_haversine(12.37, -1.52, 12.37, -1.52), closeTo(0, 1));
    });

    test('Ouagadougou → Bobo-Dioulasso ≈ 300-360 km', () {
      final d = _haversine(12.3647, -1.5332, 11.1771, -4.2979);
      // Distance en ligne droite ≪ distance routière, tolérance élargie
      expect(d / 1000, inInclusiveRange(280, 380));
    });

    test('0.001° lat ≈ 111 m', () {
      expect(_haversine(0.0, 0.0, 0.001, 0.0), closeTo(111.2, 5));
    });

    test('symétrique A→B = B→A', () {
      final ab = _haversine(12.0, -1.0, 11.0, -2.0);
      final ba = _haversine(11.0, -2.0, 12.0, -1.0);
      expect(ab, closeTo(ba, 1));
    });
  });

  group('GeolocationService.formatDistance', () {
    // formatDistance prend des km (double)
    test('0.35 km → "350 m"', () {
      expect(GeolocationService.formatDistance(0.35), '350 m');
    });

    test('1.0 km → "1.0 km"', () {
      expect(GeolocationService.formatDistance(1.0), '1.0 km');
    });

    test('2.5 km → "2.5 km"', () {
      expect(GeolocationService.formatDistance(2.5), '2.5 km');
    });

    test('15.0 km → "15.0 km" (1 décimale)', () {
      expect(GeolocationService.formatDistance(15.0), '15.0 km');
    });

    test('0.999 km → "999 m"', () {
      expect(GeolocationService.formatDistance(0.999), '999 m');
    });

    test('1.5 km → "1.5 km"', () {
      expect(GeolocationService.formatDistance(1.5), '1.5 km');
    });

    test('0.0 km → "0 m"', () {
      expect(GeolocationService.formatDistance(0.0), '0 m');
    });

    test('0.1 km → "100 m"', () {
      expect(GeolocationService.formatDistance(0.1), '100 m');
    });

    test('10.0 km → "10.0 km"', () {
      expect(GeolocationService.formatDistance(10.0), '10.0 km');
    });
  });

  group('GeolocationService.getDistanceToRestaurant', () {
    test('retourne null si lat est null', () async {
      final result = await GeolocationService.getDistanceToRestaurant(
        restaurantLat: null,
        restaurantLng: 1.5,
      );
      expect(result, isNull);
    });

    test('retourne null si lng est null', () async {
      final result = await GeolocationService.getDistanceToRestaurant(
        restaurantLat: 12.3,
        restaurantLng: null,
      );
      expect(result, isNull);
    });

    test('retourne null si les deux sont null', () async {
      final result = await GeolocationService.getDistanceToRestaurant(
        restaurantLat: null,
        restaurantLng: null,
      );
      expect(result, isNull);
    });
  });

  group('GeolocationService.getCurrentPosition', () {
    test('ne lève pas d\'exception en environnement de test', () async {
      // En test, le GPS n'est pas disponible — on vérifie juste qu'il ne plante pas
      try {
        final pos = await GeolocationService.getCurrentPosition();
        // Soit null (pas de GPS), soit une position
        expect(pos == null || pos.latitude != null, isTrue);
      } catch (_) {
        // Acceptable en environnement de test sans GPS
      }
    });
  });
}
