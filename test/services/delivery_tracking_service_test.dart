import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:noogo/services/delivery_tracking_service.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // DriverLocation
  // ──────────────────────────────────────────────────────────────────────────

  group('DriverLocation', () {
    test('fromJson parse les coordonnées en double', () {
      final loc = DriverLocation.fromJson({
        'latitude': 12.3714,
        'longitude': -1.5197,
        'timestamp': '2026-04-22T10:00:00.000Z',
      });

      expect(loc.latitude, closeTo(12.3714, 0.0001));
      expect(loc.longitude, closeTo(-1.5197, 0.0001));
      expect(loc.timestamp.year, equals(2026));
    });

    test('fromJson accepte latitude/longitude sous forme int', () {
      final loc = DriverLocation.fromJson({
        'latitude': 12,
        'longitude': -1,
        'timestamp': '2026-04-22T10:00:00.000Z',
      });

      expect(loc.latitude, equals(12.0));
      expect(loc.longitude, equals(-1.0));
    });

    test('fromJson utilise DateTime.now() si timestamp absent ou invalide', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final loc = DriverLocation.fromJson({
        'latitude': 12.0,
        'longitude': -1.0,
        'timestamp': null,
      });
      expect(loc.timestamp.isAfter(before), isTrue);
    });

    test('fromJson utilise DateTime.now() si timestamp invalide', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final loc = DriverLocation.fromJson({
        'latitude': 12.0,
        'longitude': -1.0,
        'timestamp': 'not-a-date',
      });
      expect(loc.timestamp.isAfter(before), isTrue);
    });

    test('toLatLng retourne le bon LatLng', () {
      final loc = DriverLocation.fromJson({
        'latitude': 12.3714,
        'longitude': -1.5197,
        'timestamp': '2026-04-22T10:00:00.000Z',
      });
      final latlng = loc.toLatLng();
      expect(latlng.latitude, closeTo(12.3714, 0.0001));
      expect(latlng.longitude, closeTo(-1.5197, 0.0001));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DeliveryStatusEvent
  // ──────────────────────────────────────────────────────────────────────────

  group('DeliveryStatusEvent', () {
    test('fromJson parse le statut et le nom du livreur', () {
      final event = DeliveryStatusEvent.fromJson({
        'status': 'picked_up',
        'driver_name': 'Moussa',
        'timestamp': '2026-04-22T10:05:00.000Z',
      });

      expect(event.status, equals('picked_up'));
      expect(event.driverName, equals('Moussa'));
      expect(event.timestamp.month, equals(4));
    });

    test('fromJson accepte driver_name null', () {
      final event = DeliveryStatusEvent.fromJson({
        'status': 'delivered',
        'timestamp': '2026-04-22T11:00:00.000Z',
      });

      expect(event.driverName, isNull);
      expect(event.status, equals('delivered'));
    });

    test('fromJson renvoie statut vide si status absent', () {
      final event = DeliveryStatusEvent.fromJson({
        'timestamp': '2026-04-22T11:00:00.000Z',
      });

      expect(event.status, equals(''));
    });

    test('fromJson utilise DateTime.now() si timestamp null', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final event = DeliveryStatusEvent.fromJson({
        'status': 'on_way',
        'timestamp': null,
      });
      expect(event.timestamp.isAfter(before), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DeliveryTrackingService.distanceKm (méthode statique pure)
  // ──────────────────────────────────────────────────────────────────────────

  group('DeliveryTrackingService.distanceKm', () {
    test('distance entre deux points identiques est zéro', () {
      final point = const LatLng(12.3714, -1.5197);
      expect(DeliveryTrackingService.distanceKm(point, point), equals(0.0));
    });

    test('distance Ouagadougou ↔ Bobo-Dioulasso ≈ 350 km', () {
      const ouaga = LatLng(12.3714, -1.5197);
      const bobo = LatLng(11.1771, -4.2979);
      final dist = DeliveryTrackingService.distanceKm(ouaga, bobo);
      expect(dist, greaterThan(300));
      expect(dist, lessThan(400));
    });

    test('distance courte dans la même ville est positive', () {
      const a = LatLng(12.3650, -1.5350);
      const b = LatLng(12.3700, -1.5300);
      final dist = DeliveryTrackingService.distanceKm(a, b);
      expect(dist, greaterThan(0));
      expect(dist, lessThan(5)); // quelques centaines de mètres, bien < 5 km
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DeliveryTrackingService.etaMinutes (méthode statique pure)
  // ──────────────────────────────────────────────────────────────────────────

  group('DeliveryTrackingService.etaMinutes', () {
    test('eta pour deux points identiques est 0', () {
      final point = const LatLng(12.3714, -1.5197);
      expect(DeliveryTrackingService.etaMinutes(point, point), equals(0));
    });

    test('eta est positif pour des points différents', () {
      const a = LatLng(12.3650, -1.5350);
      const b = LatLng(12.3900, -1.5100);
      expect(DeliveryTrackingService.etaMinutes(a, b), greaterThan(0));
    });

    test('eta arrondi vers le haut (ceil)', () {
      // 1 km à 20 km/h = 3 minutes exactement → ceil = 3
      // 1.1 km à 20 km/h = 3.3 min → ceil = 4
      // On vérifie juste que le résultat est un entier >= 1
      const a = LatLng(12.3650, -1.5350);
      const b = LatLng(12.3700, -1.5250);
      final eta = DeliveryTrackingService.etaMinutes(a, b);
      expect(eta, isA<int>());
      expect(eta, greaterThanOrEqualTo(1));
    });

    test('eta longue distance est proportionnel à la distance', () {
      const ouaga = LatLng(12.3714, -1.5197);
      const bobo = LatLng(11.1771, -4.2979);
      // ~350 km à 20 km/h = ~1050 min
      final eta = DeliveryTrackingService.etaMinutes(ouaga, bobo);
      expect(eta, greaterThan(900));
      expect(eta, lessThan(1200));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DeliveryTrackingService — état singleton
  // ──────────────────────────────────────────────────────────────────────────

  group('DeliveryTrackingService singleton', () {
    test('retourne toujours la même instance', () {
      final a = DeliveryTrackingService();
      final b = DeliveryTrackingService();
      expect(identical(a, b), isTrue);
    });

    test('isSubscribed est false par défaut', () {
      expect(DeliveryTrackingService().isSubscribed, isFalse);
    });

    test('driverLocationStream est un broadcast stream', () {
      final stream = DeliveryTrackingService().driverLocationStream;
      expect(stream.isBroadcast, isTrue);
    });

    test('deliveryStatusStream est un broadcast stream', () {
      final stream = DeliveryTrackingService().deliveryStatusStream;
      expect(stream.isBroadcast, isTrue);
    });
  });
}
