import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/models/app_notification.dart';

void main() {
  final baseTimestamp = DateTime(2026, 4, 14, 10, 30);

  AppNotification _makeNotification({
    String id = 'notif_1',
    String title = 'Commande confirmée',
    String body = 'Votre commande #42 est confirmée',
    bool isRead = false,
    String? type = 'order',
    Map<String, dynamic>? data,
  }) =>
      AppNotification(
        id: id,
        title: title,
        body: body,
        timestamp: baseTimestamp,
        isRead: isRead,
        type: type,
        data: data,
      );

  group('AppNotification.constructor', () {
    test('crée une notification avec les valeurs fournies', () {
      final notif = _makeNotification();

      expect(notif.id, 'notif_1');
      expect(notif.title, 'Commande confirmée');
      expect(notif.body, 'Votre commande #42 est confirmée');
      expect(notif.timestamp, baseTimestamp);
      expect(notif.isRead, false);
      expect(notif.type, 'order');
    });

    test('isRead vaut false par défaut', () {
      final notif = AppNotification(
        id: 'x',
        title: 'Test',
        body: 'body',
        timestamp: baseTimestamp,
      );
      expect(notif.isRead, false);
    });

    test('type et data sont nullable', () {
      final notif = AppNotification(
        id: 'x',
        title: 'Test',
        body: 'body',
        timestamp: baseTimestamp,
      );
      expect(notif.type, isNull);
      expect(notif.data, isNull);
    });
  });

  group('AppNotification.copyWith', () {
    test('retourne une copie avec isRead modifié', () {
      final notif = _makeNotification(isRead: false);
      final read = notif.copyWith(isRead: true);

      expect(read.isRead, true);
      expect(read.id, notif.id);
      expect(read.title, notif.title);
      expect(read.body, notif.body);
    });

    test('retourne une copie avec title modifié', () {
      final notif = _makeNotification();
      final updated = notif.copyWith(title: 'Nouveau titre');

      expect(updated.title, 'Nouveau titre');
      expect(updated.body, notif.body);
      expect(updated.isRead, notif.isRead);
    });

    test('ne modifie pas l\'original', () {
      final notif = _makeNotification(isRead: false);
      notif.copyWith(isRead: true);

      expect(notif.isRead, false);
    });

    test('copyWith sans arguments retourne une copie identique', () {
      final notif = _makeNotification(data: {'orderId': '42'});
      final copy = notif.copyWith();

      expect(copy.id, notif.id);
      expect(copy.isRead, notif.isRead);
      expect(copy.data, notif.data);
    });
  });

  group('AppNotification.toJson', () {
    test('sérialise correctement en JSON', () {
      final notif = _makeNotification(type: 'promo', data: {'code': 'PROMO10'});
      final json = notif.toJson();

      expect(json['id'], 'notif_1');
      expect(json['title'], 'Commande confirmée');
      expect(json['body'], 'Votre commande #42 est confirmée');
      expect(json['isRead'], false);
      expect(json['type'], 'promo');
      expect(json['data'], {'code': 'PROMO10'});
    });

    test('timestamp sérialisé en ISO 8601', () {
      final notif = _makeNotification();
      final json = notif.toJson();

      expect(json['timestamp'], baseTimestamp.toIso8601String());
    });
  });

  group('AppNotification.fromJson', () {
    test('désérialise correctement depuis JSON', () {
      final json = {
        'id': 'notif_42',
        'title': 'Livraison en route',
        'body': 'Votre commande arrive dans 10 min',
        'timestamp': baseTimestamp.toIso8601String(),
        'isRead': true,
        'type': 'delivery',
        'data': {'orderId': '42'},
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif_42');
      expect(notif.title, 'Livraison en route');
      expect(notif.isRead, true);
      expect(notif.type, 'delivery');
      expect(notif.timestamp, baseTimestamp);
    });

    test('isRead vaut false si absent du JSON', () {
      final json = {
        'id': 'x',
        'title': 'Test',
        'body': 'body',
        'timestamp': baseTimestamp.toIso8601String(),
      };

      final notif = AppNotification.fromJson(json);
      expect(notif.isRead, false);
    });

    test('round-trip toJson/fromJson préserve les données', () {
      final original = _makeNotification(
        isRead: true,
        type: 'order',
        data: {'orderId': '7'},
      );
      final restored = AppNotification.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.body, original.body);
      expect(restored.isRead, original.isRead);
      expect(restored.type, original.type);
      expect(restored.timestamp, original.timestamp);
    });
  });
}
