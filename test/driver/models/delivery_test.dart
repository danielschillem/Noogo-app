import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/driver/models/delivery.dart';

void main() {
  group('Delivery model', () {
    final sampleJson = {
      'id': 1,
      'order_id': 42,
      'driver_id': 5,
      'status': 'assigned',
      'pickup_address': 'Maquis Bonne Table',
      'delivery_address': '123 Rue de la Paix',
      'pickup_lat': 12.37,
      'pickup_lng': -1.52,
      'delivery_lat': 12.38,
      'delivery_lng': -1.53,
      'fee': 500.0,
      'customer_phone': '70000000',
      'customer_name': 'Awa',
      'restaurant_name': 'Maquis Bonne Table',
      'total_amount': 3000,
      'assigned_at': '2026-04-20T10:00:00.000Z',
      'picked_up_at': null,
      'delivered_at': null,
      'created_at': '2026-04-20T09:55:00.000Z',
      'order': {
        'total_amount': 3000,
        'items': [
          {
            'dish': {'nom': 'Riz gras'},
            'quantity': 2,
            'unit_price': 1500,
          },
        ],
      },
    };

    test('fromJson parses correctly', () {
      final d = Delivery.fromJson(sampleJson);

      expect(d.id, 1);
      expect(d.orderId, 42);
      expect(d.driverId, 5);
      expect(d.status, 'assigned');
      expect(d.pickupAddress, 'Maquis Bonne Table');
      expect(d.deliveryAddress, '123 Rue de la Paix');
      expect(d.pickupLat, 12.37);
      expect(d.pickupLng, -1.52);
      expect(d.deliveryLat, 12.38);
      expect(d.deliveryLng, -1.53);
      expect(d.fee, 500.0);
      expect(d.customerPhone, '70000000');
      expect(d.customerName, 'Awa');
      expect(d.totalAmount, 3000.0);
      expect(d.assignedAt, isNotNull);
      expect(d.pickedUpAt, isNull);
      expect(d.items.length, 1);
    });

    test('fromJson with string numeric values', () {
      final d = Delivery.fromJson({
        'id': '7',
        'order_id': '99',
        'driver_id': '3',
        'status': 'on_way',
        'fee': '750',
        'total_amount': '5000',
        'created_at': '2026-04-22T12:00:00Z',
      });

      expect(d.id, 7);
      expect(d.orderId, 99);
      expect(d.driverId, 3);
      expect(d.fee, 750.0);
      expect(d.totalAmount, 5000.0);
    });

    test('fromJson with null values', () {
      final d = Delivery.fromJson({
        'id': 1,
        'order_id': 1,
        'status': 'pending',
        'created_at': '2026-04-22T12:00:00Z',
      });

      expect(d.driverId, isNull);
      expect(d.pickupAddress, isNull);
      expect(d.deliveryAddress, isNull);
      expect(d.fee, isNull);
      expect(d.items, isEmpty);
    });

    test('pickupLatLng returns LatLng when both coords set', () {
      final d = Delivery.fromJson(sampleJson);
      expect(d.pickupLatLng, isNotNull);
      expect(d.pickupLatLng!.latitude, 12.37);
      expect(d.pickupLatLng!.longitude, -1.52);
    });

    test('pickupLatLng returns null when coords missing', () {
      final d = Delivery.fromJson({
        'id': 1,
        'order_id': 1,
        'status': 'pending',
        'created_at': '2026-04-22T12:00:00Z',
      });
      expect(d.pickupLatLng, isNull);
    });

    test('deliveryLatLng returns LatLng when both coords set', () {
      final d = Delivery.fromJson(sampleJson);
      expect(d.deliveryLatLng, isNotNull);
      expect(d.deliveryLatLng!.latitude, 12.38);
    });

    test('isActive for active statuses', () {
      for (final s in ['assigned', 'picked_up', 'on_way']) {
        final d = Delivery.fromJson({
          'id': 1,
          'order_id': 1,
          'status': s,
          'created_at': '2026-04-22T12:00:00Z',
        });
        expect(d.isActive, isTrue, reason: '$s should be active');
      }
    });

    test('isActive false for terminal statuses', () {
      for (final s in ['delivered', 'failed', 'pending']) {
        final d = Delivery.fromJson({
          'id': 1,
          'order_id': 1,
          'status': s,
          'created_at': '2026-04-22T12:00:00Z',
        });
        expect(d.isActive, isFalse, reason: '$s should not be active');
      }
    });

    test('isCompleted and isFailed', () {
      final delivered = Delivery.fromJson({
        'id': 1,
        'order_id': 1,
        'status': 'delivered',
        'created_at': '2026-04-22T12:00:00Z',
      });
      expect(delivered.isCompleted, isTrue);
      expect(delivered.isFailed, isFalse);

      final failed = Delivery.fromJson({
        'id': 2,
        'order_id': 2,
        'status': 'failed',
        'created_at': '2026-04-22T12:00:00Z',
      });
      expect(failed.isCompleted, isFalse);
      expect(failed.isFailed, isTrue);
    });

    test('statusLabel returns correct French labels', () {
      final labels = {
        'pending': 'En attente',
        'assigned': 'Assignée',
        'picked_up': 'Récupérée',
        'on_way': 'En route',
        'delivered': 'Livrée',
        'failed': 'Échouée',
      };

      for (final entry in labels.entries) {
        final d = Delivery.fromJson({
          'id': 1,
          'order_id': 1,
          'status': entry.key,
          'created_at': '2026-04-22T12:00:00Z',
        });
        expect(d.statusLabel, entry.value);
      }
    });

    test('nextStatus transitions correctly', () {
      final transitions = {
        'assigned': 'picked_up',
        'picked_up': 'on_way',
        'on_way': 'delivered',
        'delivered': null,
        'failed': null,
        'pending': null,
      };

      for (final entry in transitions.entries) {
        final d = Delivery.fromJson({
          'id': 1,
          'order_id': 1,
          'status': entry.key,
          'created_at': '2026-04-22T12:00:00Z',
        });
        expect(d.nextStatus, entry.value,
            reason: '${entry.key} → ${entry.value}');
      }
    });

    test('nextStatusLabel returns French labels', () {
      final labels = {
        'assigned': 'Commande récupérée',
        'picked_up': 'En route vers le client',
        'on_way': 'Livrée au client',
        'delivered': null,
      };

      for (final entry in labels.entries) {
        final d = Delivery.fromJson({
          'id': 1,
          'order_id': 1,
          'status': entry.key,
          'created_at': '2026-04-22T12:00:00Z',
        });
        expect(d.nextStatusLabel, entry.value);
      }
    });

    test('restaurant name from nested order json', () {
      final d = Delivery.fromJson({
        'id': 1,
        'order_id': 1,
        'status': 'assigned',
        'created_at': '2026-04-22T12:00:00Z',
        'restaurant': {'nom': 'Chez Bouba', 'telephone': '70111111'},
      });
      expect(d.restaurantName, 'Chez Bouba');
      expect(d.restaurantPhone, '70111111');
    });
  });

  group('DeliveryItem model', () {
    test('fromJson parses dish name', () {
      final item = DeliveryItem.fromJson({
        'dish': {'nom': 'Poulet braisé'},
        'quantity': 3,
        'unit_price': 2500,
      });

      expect(item.name, 'Poulet braisé');
      expect(item.quantity, 3);
      expect(item.unitPrice, 2500.0);
    });

    test('fromJson with fallback name field', () {
      final item = DeliveryItem.fromJson({
        'name': 'Alloco',
        'quantity': 1,
        'unit_price': 500,
      });
      expect(item.name, 'Alloco');
    });

    test('fromJson with string quantity', () {
      final item = DeliveryItem.fromJson({
        'name': 'Riz',
        'quantity': '2',
        'prix_unitaire': 1000,
      });
      expect(item.quantity, 2);
      expect(item.unitPrice, 1000.0);
    });
  });
}
