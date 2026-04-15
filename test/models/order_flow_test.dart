import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/dish.dart';

Dish _dish({int id = 1, double price = 1000}) => Dish(
      id: id,
      name: 'Plat $id',
      description: '',
      price: price,
      imageUrl: '',
      categoryId: 1,
      category: 'Cat',
      isAvailable: true,
    );

Order _order({
  List<OrderItem>? items,
  OrderStatus status = OrderStatus.pending,
  OrderType type = OrderType.surPlace,
  String paymentMethod = 'cash',
  String? table,
}) =>
    Order(
      id: 1,
      items: items ?? [OrderItem(dish: _dish(), quantity: 1)],
      status: status,
      orderDate: DateTime(2026, 1, 1),
      paymentMethod: paymentMethod,
      orderType: type,
      table: table,
    );

void main() {
  setUpAll(() async {
    await dotenv.load(
      fileName: 'assets/env/.env',
      isOptional: true,
      mergeWith: {
        'API_BASE_URL': 'http://localhost/api',
        'ENVIRONMENT': 'test'
      },
    );
  });

  // ── OrderItem ──────────────────────────────────────────────────────────────

  group('OrderItem', () {
    test('totalPrice = quantity × dish.price', () {
      final item = OrderItem(dish: _dish(price: 1500), quantity: 3);
      expect(item.totalPrice, 4500);
    });

    test('totalPrice with fractional price', () {
      final item = OrderItem(dish: _dish(price: 1333.33), quantity: 2);
      expect(item.totalPrice, closeTo(2666.66, 0.01));
    });

    test('fromJson / toJson — toJson produces expected keys', () {
      final item = OrderItem(dish: _dish(id: 7, price: 2000), quantity: 4);
      final json = item.toJson();
      // toJson() uses english keys matching server output format
      expect(json['quantity'], 4);
      expect(json['dish']['price'], 2000);
      expect(json['dish']['id'], 7);
    });
  });

  // ── Order.totalAmount ──────────────────────────────────────────────────────

  group('Order.totalAmount', () {
    test('single item', () {
      final o =
          _order(items: [OrderItem(dish: _dish(price: 2000), quantity: 1)]);
      expect(o.totalAmount, 2000);
    });

    test('multiple items accumulated correctly', () {
      final o = _order(items: [
        OrderItem(dish: _dish(id: 1, price: 1000), quantity: 2),
        OrderItem(dish: _dish(id: 2, price: 500), quantity: 3),
      ]);
      expect(o.totalAmount, 3500);
    });

    test('empty items list gives 0', () {
      final o = _order(items: []);
      expect(o.totalAmount, 0);
    });
  });

  // ── Order.statusText ───────────────────────────────────────────────────────

  group('Order.statusText', () {
    final cases = {
      OrderStatus.pending: 'En attente',
      OrderStatus.confirmed: 'Confirmée',
      OrderStatus.preparing: 'En préparation',
      OrderStatus.ready: 'Prête',
      OrderStatus.delivered: 'Livrée',
      OrderStatus.cancelled: 'Annulée',
      OrderStatus.completed: 'Terminée',
    };

    cases.forEach((status, expected) {
      test('$status → "$expected"', () {
        expect(_order(status: status).statusText, expected);
      });
    });
  });

  // ── Order.orderTypeText ────────────────────────────────────────────────────

  group('Order.orderTypeText', () {
    test(
        'surPlace',
        () => expect(
            _order(type: OrderType.surPlace).orderTypeText, 'Sur place'));
    test(
        'aEmporter',
        () => expect(
            _order(type: OrderType.aEmporter).orderTypeText, 'À emporter'));
    test(
        'livraison',
        () => expect(
            _order(type: OrderType.livraison).orderTypeText, 'Livraison'));
  });

  // ── Order.isMobileMoneyPayment ─────────────────────────────────────────────

  group('Order.isMobileMoneyPayment', () {
    test('true when paymentMethod is Mobile Money', () {
      expect(
          _order(paymentMethod: 'Mobile Money').isMobileMoneyPayment, isTrue);
    });

    test('false when paymentMethod is cash', () {
      expect(_order(paymentMethod: 'cash').isMobileMoneyPayment, isFalse);
    });
  });

  // ── Order.parseOrderType ───────────────────────────────────────────────────

  group('Order.parseOrderType', () {
    final cases = {
      'sur_place': OrderType.surPlace,
      'sur place': OrderType.surPlace,
      'surplace': OrderType.surPlace,
      'a_emporter': OrderType.aEmporter,
      'à emporter': OrderType.aEmporter,
      'livraison': OrderType.livraison,
      'delivery': OrderType.livraison,
      null: OrderType.surPlace,
      'unknown': OrderType.surPlace,
    };
    cases.forEach((input, expected) {
      test('parseOrderType("$input") → $expected', () {
        expect(Order.parseOrderType(input), expected);
      });
    });
  });

  // ── Status flow ────────────────────────────────────────────────────────────

  group('Order status mutation (simulated flow)', () {
    test('status can be mutated from pending → confirmed', () {
      final o = _order(status: OrderStatus.pending);
      o.status = OrderStatus.confirmed;
      expect(o.status, OrderStatus.confirmed);
      expect(o.statusText, 'Confirmée');
    });

    test('full lifecycle: pending → confirmed → preparing → ready → delivered',
        () {
      final o = _order(status: OrderStatus.pending);
      final flow = [
        OrderStatus.confirmed,
        OrderStatus.preparing,
        OrderStatus.ready,
        OrderStatus.delivered,
      ];
      for (final next in flow) {
        o.status = next;
        expect(o.status, next);
      }
      expect(o.statusText, 'Livrée');
    });

    test('cancelled order has correct text', () {
      final o = _order(status: OrderStatus.pending);
      o.status = OrderStatus.cancelled;
      expect(o.statusText, 'Annulée');
    });
  });
}
