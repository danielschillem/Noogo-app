import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/models/category.dart';
import 'package:noogo/models/otp_payment_request.dart';

void main() {
  group('Category.fromJson', () {
    test('parses basic category correctly', () {
      final cat = Category.fromJson({
        'id': 5,
        'nom': 'EntrÃ©es',
        'description': 'Les entrÃ©es du jour',
      });
      expect(cat.id, 5);
      expect(cat.name, 'EntrÃ©es');
      expect(cat.description, 'Les entrÃ©es du jour');
    });

    test('name field aliases: nom', () {
      final cat = Category.fromJson({'id': 1, 'nom': 'Grillades'});
      expect(cat.name, 'Grillades');
    });

    test('name field aliases: name', () {
      final cat = Category.fromJson({'id': 2, 'name': 'Boissons'});
      expect(cat.name, 'Boissons');
    });

    test('description from categorie_description field', () {
      final cat = Category.fromJson({
        'id': 3,
        'nom': 'Test',
        'categorie_description': 'Desc from alt field',
      });
      expect(cat.description, 'Desc from alt field');
    });

    test('imageUrl defaults to empty when no image', () {
      final cat = Category.fromJson({'id': 1, 'nom': 'X'});
      expect(cat.imageUrl, isA<String>());
    });

    test('imageUrl parses from image_url field', () {
      final cat = Category.fromJson({
        'id': 1,
        'nom': 'X',
        'image_url': 'https://example.com/img.jpg',
      });
      expect(cat.imageUrl, contains('example.com'));
    });

    test('id accepts int or string', () {
      final cat1 = Category.fromJson({'id': 7, 'nom': 'A'});
      expect(cat1.id, 7);

      // String id
      final cat2 = Category.fromJson({'id': '8', 'nom': 'B'});
      expect(cat2.id, 8);
    });
  });

  group('OtpPaymentRequest.toJson', () {
    OtpPaymentRequest make() => OtpPaymentRequest(
          orderType: 'table',
          tableNumber: 'T1',
          phone: '70000000',
          provider: 'orange',
          amount: 2500,
          otp: '1234',
          items: [
            {'dish_id': 1, 'quantity': 2}
          ],
        );

    test('toJson has required keys', () {
      final json = make().toJson();
      expect(json['order_type'], 'table');
      expect(json['table_number'], 'T1');
      expect(json['phone'], '70000000');
      expect(json['payment_method'], 'mobile_money');
      expect(json['provider'], 'orange');
      expect(json['amount'], 2500);
      expect(json['otp'], '1234');
      expect(json['otp_phone'], '70000000');
      expect(json['items'], isA<List>());
    });

    test('toJson with null tableNumber', () {
      final req = OtpPaymentRequest(
        orderType: 'takeaway',
        tableNumber: null,
        phone: '70000001',
        provider: 'wave',
        amount: 1000,
        otp: '5678',
        items: [],
      );
      final json = req.toJson();
      expect(json['table_number'], isNull);
      expect(json['order_type'], 'takeaway');
    });

    test('items list is included correctly', () {
      final req = OtpPaymentRequest(
        orderType: 'table',
        tableNumber: 'B3',
        phone: '76000000',
        provider: 'moov',
        amount: 3000,
        otp: '9999',
        items: [
          {'dish_id': 10, 'quantity': 1},
          {'dish_id': 11, 'quantity': 3},
        ],
      );
      final json = req.toJson();
      expect((json['items'] as List).length, 2);
    });
  });

  group('Category.toJson / toString / equality', () {
    final cat = Category.fromJson(
        {'id': 9, 'nom': 'Desserts', 'description': 'Douceurs'});

    test('toJson contient les clés attendues', () {
      final json = cat.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('name'), isTrue);
    });

    test('toJson retourne les bonnes valeurs', () {
      final json = cat.toJson();
      expect(json['id'], 9);
      expect(json['name'], 'Desserts');
    });

    test('toString contient le nom', () {
      expect(cat.toString(), contains('Desserts'));
    });

    test('egale si même id', () {
      final cat2 = Category.fromJson({'id': 9, 'nom': 'Autre'});
      expect(cat == cat2, isTrue);
    });

    test('different si id different', () {
      final cat2 = Category.fromJson({'id': 99, 'nom': 'Desserts'});
      expect(cat == cat2, isFalse);
    });

    test('hashCode pareil si même id', () {
      final cat2 = Category.fromJson({'id': 9, 'nom': 'X'});
      expect(cat.hashCode, cat2.hashCode);
    });
  });

  group('Category.fromJson variantes id/image', () {
    test('id via categorie_id', () {
      final cat = Category.fromJson({'categorie_id': 42, 'nom': 'Test'});
      expect(cat.id, 42);
    });

    test('id via category_id', () {
      final cat = Category.fromJson({'category_id': 15, 'name': 'Grillades'});
      expect(cat.id, 15);
    });

    test('image via categorie_image', () {
      final cat = Category.fromJson({
        'id': 1,
        'nom': 'X',
        'categorie_image': 'storage/cat.jpg',
      });
      expect(cat.imageUrl, isA<String>());
    });

    test('image via liste', () {
      final cat = Category.fromJson({
        'id': 2,
        'nom': 'Y',
        'image_url': ['https://example.com/a.jpg'],
      });
      expect(cat.imageUrl, isA<String>());
    });

    test('image via Map avec url', () {
      final cat = Category.fromJson({
        'id': 3,
        'nom': 'Z',
        'image_url': {'url': 'https://example.com/b.jpg'},
      });
      expect(cat.imageUrl, isA<String>());
    });

    test('image via Map avec chemin', () {
      final cat = Category.fromJson({
        'id': 4,
        'nom': 'W',
        'categorie_image': {'chemin': 'storage/img.jpg'},
      });
      expect(cat.imageUrl, isA<String>());
    });

    test('description via description field', () {
      final cat = Category.fromJson({
        'id': 5,
        'nom': 'Plats',
        'description': 'Tous les plats',
      });
      expect(cat.description, 'Tous les plats');
    });
  });
}
