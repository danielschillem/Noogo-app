import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noogo/services/notification_service.dart';
import 'package:noogo/models/app_notification.dart';

AppNotification _makeNotif({
  String id = '1',
  String title = 'Test',
  String body = 'Body',
  bool isRead = false,
  String type = 'order',
  DateTime? timestamp,
}) =>
    AppNotification(
      id: id,
      title: title,
      body: body,
      timestamp: timestamp ?? DateTime.now(),
      isRead: isRead,
      type: type,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationService.loadNotifications', () {
    test('retourne liste vide si aucune notification sauvegardée', () async {
      final result = await NotificationService.loadNotifications();
      expect(result, isEmpty);
    });

    test('retourne liste vide si clé manquante', () async {
      SharedPreferences.setMockInitialValues({});
      final result = await NotificationService.loadNotifications();
      expect(result, isEmpty);
    });
  });

  group('NotificationService.saveNotifications + loadNotifications', () {
    test('sauvegarde et recharge une notification', () async {
      final notif = _makeNotif(id: 'a1', title: 'Commande prête');
      await NotificationService.saveNotifications([notif]);

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('a1'));
      expect(loaded.first.title, equals('Commande prête'));
    });

    test('sauvegarde plusieurs notifications', () async {
      final notifs = [
        _makeNotif(id: '1', title: 'Notif 1'),
        _makeNotif(id: '2', title: 'Notif 2'),
        _makeNotif(id: '3', title: 'Notif 3'),
      ];
      await NotificationService.saveNotifications(notifs);

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.length, equals(3));
    });

    test('respecte les métadonnées isRead et type', () async {
      final notif =
          _makeNotif(id: 'r1', isRead: true, type: 'promo', body: 'Promo!');
      await NotificationService.saveNotifications([notif]);

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.first.isRead, isTrue);
      expect(loaded.first.type, equals('promo'));
      expect(loaded.first.body, equals('Promo!'));
    });
  });

  group('NotificationService.addNotification', () {
    test('ajoute une notification à une liste vide', () async {
      final notif = _makeNotif(id: 'new1', title: 'Nouvelle commande');
      await NotificationService.addNotification(notif);

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.length, equals(1));
      expect(loaded.first.title, equals('Nouvelle commande'));
    });

    test('ajoute en tête de liste (plus récent en premier)', () async {
      await NotificationService.saveNotifications([
        _makeNotif(id: 'old1', title: 'Ancienne'),
      ]);

      await NotificationService.addNotification(
          _makeNotif(id: 'new1', title: 'Nouvelle'));

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.first.title, equals('Nouvelle'));
    });

    test(
        'n\'ajoute pas de doublon si notification avec même id existe déjà',
        () async {
      await NotificationService.addNotification(_makeNotif(id: 'dup1'));
      await NotificationService.addNotification(_makeNotif(id: 'dup1'));

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.length, equals(1));
    });
  });

  group('NotificationService.markAsRead', () {
    test('marque une notification comme lue', () async {
      await NotificationService.saveNotifications([
        _makeNotif(id: 'r1', isRead: false),
      ]);

      await NotificationService.markAsRead('r1');

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.first.isRead, isTrue);
    });

    test('ne plante pas si l\'id est introuvable', () async {
      await NotificationService.saveNotifications([
        _makeNotif(id: 'r1'),
      ]);
      // N'existe pas → ne doit pas lancer d'exception
      await expectLater(
        NotificationService.markAsRead('nonexistent'),
        completes,
      );
    });
  });

  group('NotificationService.markAllAsRead', () {
    test('marque toutes les notifications comme lues', () async {
      await NotificationService.saveNotifications([
        _makeNotif(id: '1', isRead: false),
        _makeNotif(id: '2', isRead: false),
        _makeNotif(id: '3', isRead: true),
      ]);

      await NotificationService.markAllAsRead();

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.every((n) => n.isRead), isTrue);
    });
  });

  group('NotificationService.deleteNotification', () {
    test('supprime une notification par id', () async {
      await NotificationService.saveNotifications([
        _makeNotif(id: 'd1'),
        _makeNotif(id: 'd2'),
      ]);

      await NotificationService.deleteNotification('d1');

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('d2'));
    });

    test('ne plante pas si id introuvable', () async {
      await NotificationService.saveNotifications([_makeNotif(id: 'x')]);
      await expectLater(
          NotificationService.deleteNotification('nonexistent'), completes);
      final loaded = await NotificationService.loadNotifications();
      expect(loaded.length, equals(1));
    });
  });

  group('NotificationService.clearAllNotifications', () {
    test('vide complètement la liste', () async {
      await NotificationService.saveNotifications([
        _makeNotif(id: '1'),
        _makeNotif(id: '2'),
      ]);

      await NotificationService.clearAllNotifications();

      final loaded = await NotificationService.loadNotifications();
      expect(loaded, isEmpty);
    });
  });

  group('NotificationService.getUnreadCount', () {
    test('retourne 0 si liste vide', () async {
      final count = await NotificationService.getUnreadCount();
      expect(count, equals(0));
    });

    test('compte les non lues', () async {
      await NotificationService.saveNotifications([
        _makeNotif(id: '1', isRead: false),
        _makeNotif(id: '2', isRead: true),
        _makeNotif(id: '3', isRead: false),
      ]);

      final count = await NotificationService.getUnreadCount();
      expect(count, equals(2));
    });
  });

  group('NotificationService.cleanOldNotifications', () {
    test('supprime les notifications plus vieilles que 30 jours', () async {
      final old = _makeNotif(
        id: 'old',
        timestamp: DateTime.now().subtract(const Duration(days: 40)),
      );
      final recent = _makeNotif(
        id: 'recent',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
      );

      await NotificationService.saveNotifications([old, recent]);
      await NotificationService.cleanOldNotifications();

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('recent'));
    });

    test('conserve toutes les notifications récentes', () async {
      await NotificationService.saveNotifications([
        _makeNotif(id: '1'),
        _makeNotif(id: '2'),
      ]);

      await NotificationService.cleanOldNotifications();

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.length, equals(2));
    });
  });

  group('NotificationService.addNotificationFromBackend', () {
    test('crée une notification depuis les données du backend', () async {
      await NotificationService.addNotificationFromBackend({
        'id': 'b1',
        'title': 'Commande confirmée',
        'body': 'Votre commande a été confirmée',
        'type': 'order',
        'timestamp': DateTime(2025, 6, 1, 10, 0).toIso8601String(),
      });

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.length, equals(1));
      expect(loaded.first.title, equals('Commande confirmée'));
    });

    test('utilise champs fallback (message au lieu de body)', () async {
      await NotificationService.addNotificationFromBackend({
        'id': 'b2',
        'title': 'Info',
        'message': 'Fallback message',
      });

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.first.body, equals('Fallback message'));
    });

    test('génère un id si absent', () async {
      await NotificationService.addNotificationFromBackend({
        'title': 'Sans id',
        'body': 'Test',
      });

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, isNotEmpty);
    });

    test('tolère les valeurs numériques dans les données', () async {
      await NotificationService.addNotificationFromBackend({
        'id': 99,
        'title': 'Numérique',
        'body': 'Test',
        'restaurant_id': 42,
      });

      final loaded = await NotificationService.loadNotifications();
      expect(loaded.isNotEmpty, isTrue);
    });
  });
}
