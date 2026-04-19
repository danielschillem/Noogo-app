import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/dish.dart';

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

  Dish makeDish({int id = 1, double price = 2000}) => Dish(
        id: id,
        name: 'Plat $id',
        description: '',
        price: price,
        imageUrl: '',
        categoryId: 1,
        category: 'Cat',
        isAvailable: true,
      );

  Order makeOrder({
    List<OrderItem>? items,
    OrderStatus status = OrderStatus.pending,
    OrderType type = OrderType.surPlace,
    String paymentMethod = 'cash',
  }) =>
      Order(
        id: 1,
        items: items ??
            [
              OrderItem(dish: makeDish(), quantity: 2),
            ],
        status: status,
        orderDate: DateTime(2026, 4, 12),
        paymentMethod: paymentMethod,
        orderType: type,
      );

  group('Order.totalAmount', () {
    test('calcule le total de plusieurs articles', () {
      final order = makeOrder(items: [
        OrderItem(dish: makeDish(price: 1000), quantity: 2),
        OrderItem(dish: makeDish(id: 2, price: 500), quantity: 3),
      ]);

      expect(order.totalAmount, 3500.0);
    });

    test('retourne 0 pour un panier vide', () {
      final order = makeOrder(items: []);
      expect(order.totalAmount, 0.0);
    });
  });

  group('Order.isMobileMoneyPayment', () {
    test('retourne true pour Mobile Money', () {
      final order = makeOrder(paymentMethod: 'Mobile Money');
      expect(order.isMobileMoneyPayment, true);
    });

    test('retourne false pour cash', () {
      final order = makeOrder(paymentMethod: 'cash');
      expect(order.isMobileMoneyPayment, false);
    });
  });

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
      test('$status â†’ "$expected"', () {
        final order = makeOrder(status: status);
        expect(order.statusText, expected);
      });
    });
  });

  group('Order.orderTypeText', () {
    test('surPlace â†’ Sur place', () {
      final order = makeOrder(type: OrderType.surPlace);
      expect(order.orderTypeText, 'Sur place');
    });

    test('aEmporter → À emporter', () {
      final order = makeOrder(type: OrderType.aEmporter);
      expect(order.orderTypeText, 'À emporter');
    });

    test('livraison â†’ Livraison', () {
      final order = makeOrder(type: OrderType.livraison);
      expect(order.orderTypeText, 'Livraison');
    });
  });

  group('Order.parseOrderType', () {
    final aliases = {
      'sur_place': OrderType.surPlace,
      'sur place': OrderType.surPlace,
      'surplace': OrderType.surPlace,
      'a_emporter': OrderType.aEmporter,
      'à emporter': OrderType.aEmporter,
      'aemporter': OrderType.aEmporter,
      'livraison': OrderType.livraison,
      'delivery': OrderType.livraison,
    };

    aliases.forEach((input, expected) {
      test('"$input" â†’ $expected', () {
        expect(Order.parseOrderType(input), expected);
      });
    });

    test('valeur inconnue â†’ surPlace par dÃ©faut', () {
      expect(Order.parseOrderType('inconnu'), OrderType.surPlace);
      expect(Order.parseOrderType(null), OrderType.surPlace);
    });
  });

  group('Order.fromJson', () {
    test('parse une commande complÃ¨te', () {
      final json = {
        'id': 42,
        'status': 'confirmed',
        'order_type': 'sur_place',
        'payment_method': 'cash',
        'table_number': 'T5',
        'order_date': '2026-04-12T10:00:00Z',
        'items': [
          {
            'quantity': 2,
            'dish': {
              'id': 1,
              'nom': 'Poulet',
              'prix': 3000,
              'description': '',
              'images': null,
              'disponibilite': true,
              'is_plat_du_jour': false,
              'temps_preparation': 20,
              'category_id': 1,
              'categorie': 'Grillades',
            }
          }
        ],
      };

      final order = Order.fromJson(json);

      expect(order.id, 42);
      expect(order.status, OrderStatus.confirmed);
      expect(order.orderType, OrderType.surPlace);
      expect(order.table, 'T5');
      expect(order.items.length, 1);
      expect(order.items[0].quantity, 2);
      expect(order.totalAmount, 6000.0);
    });
  });
}
