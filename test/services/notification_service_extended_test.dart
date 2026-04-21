import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noogo/services/notification_service.dart';
import 'package:noogo/models/app_notification.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

AppNotification _notif({
  String id = 'n1',
  String title = 'Test',
  String body = 'Corps',
  bool isRead = false,
  String type = 'order',
}) =>
    AppNotification(
      id: id,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: isRead,
      type: type,
    );

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      dotenv.loadFromString(envString: 'ENVIRONMENT=test');
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationService.loadNotifications', () {
    test('retourne liste vide si rien en cache', () async {
      final list = await NotificationService.loadNotifications();
      expect(list, isEmpty);
    });
  });

  group('NotificationService.addNotification', () {
    test('ajoute une notification', () async {
      await NotificationService.addNotification(
          _notif(id: 'a1', title: 'Bienvenue'));
      final list = await NotificationService.loadNotifications();
      expect(list.length, 1);
      expect(list.first.title, 'Bienvenue');
    });

    test('ne duplique pas une notification existante', () async {
      await NotificationService.addNotification(_notif(id: 'dup1'));
      await NotificationService.addNotification(_notif(id: 'dup1'));
      final list = await NotificationService.loadNotifications();
      expect(list.length, 1);
    });

    test('ajoute plusieurs notifications distinctes', () async {
      await NotificationService.addNotification(_notif(id: 'm1'));
      await NotificationService.addNotification(_notif(id: 'm2'));
      await NotificationService.addNotification(_notif(id: 'm3'));
      final list = await NotificationService.loadNotifications();
      expect(list.length, 3);
    });
  });

  group('NotificationService.saveNotifications', () {
    test('sauvegarde une liste et la recharge', () async {
      final notifs = [
        _notif(id: 's1', title: 'A'),
        _notif(id: 's2', title: 'B'),
      ];
      await NotificationService.saveNotifications(notifs);
      final loaded = await NotificationService.loadNotifications();
      expect(loaded.length, 2);
      expect(loaded.map((n) => n.id).toSet(), {'s1', 's2'});
    });

    test('sauvegarde une liste vide', () async {
      await NotificationService.saveNotifications([]);
      final loaded = await NotificationService.loadNotifications();
      expect(loaded, isEmpty);
    });
  });

  group('NotificationService.markAsRead', () {
    test('marque une notification comme lue', () async {
      await NotificationService.addNotification(
          _notif(id: 'r1', isRead: false));
      await NotificationService.markAsRead('r1');
      final list = await NotificationService.loadNotifications();
      expect(list.first.isRead, isTrue);
    });

    test('markAsRead avec id inexistant ne plante pas', () async {
      await expectLater(
        NotificationService.markAsRead('inexistant'),
        completes,
      );
    });
  });

  group('NotificationService.markAllAsRead', () {
    test('marque toutes les notifications comme lues', () async {
      await NotificationService.addNotification(
          _notif(id: 'all1', isRead: false));
      await NotificationService.addNotification(
          _notif(id: 'all2', isRead: false));
      await NotificationService.markAllAsRead();
      final list = await NotificationService.loadNotifications();
      expect(list.every((n) => n.isRead), isTrue);
    });

    test('markAllAsRead sur liste vide ne plante pas', () async {
      await expectLater(NotificationService.markAllAsRead(), completes);
    });
  });

  group('NotificationService.deleteNotification', () {
    test('supprime une notification spécifique', () async {
      await NotificationService.addNotification(
          _notif(id: 'del1', title: 'À supprimer'));
      await NotificationService.addNotification(
          _notif(id: 'del2', title: 'À garder'));
      await NotificationService.deleteNotification('del1');
      final list = await NotificationService.loadNotifications();
      expect(list.any((n) => n.id == 'del1'), isFalse);
      expect(list.any((n) => n.id == 'del2'), isTrue);
    });

    test('deleteNotification avec id inexistant ne plante pas', () async {
      await expectLater(
        NotificationService.deleteNotification('xxx'),
        completes,
      );
    });
  });

  group('NotificationService.clearAllNotifications', () {
    test('efface toutes les notifications', () async {
      await NotificationService.addNotification(_notif(id: 'c1'));
      await NotificationService.addNotification(_notif(id: 'c2'));
      await NotificationService.clearAllNotifications();
      final list = await NotificationService.loadNotifications();
      expect(list, isEmpty);
    });

    test('clearAllNotifications sur liste vide ne plante pas', () async {
      await expectLater(NotificationService.clearAllNotifications(), completes);
    });
  });

  group('NotificationService.createTestNotification', () {
    test('crée une notification de type order', () {
      final n = NotificationService.createTestNotification('order');
      expect(n.id, isNotEmpty);
      expect(n.title, isNotEmpty);
      expect(n.type, isNotNull);
    });

    test('crée une notification de type promo', () {
      final n = NotificationService.createTestNotification('promo');
      expect(n.id, isNotEmpty);
    });

    test('crée une notification de type delivery', () {
      final n = NotificationService.createTestNotification('delivery');
      expect(n.id, isNotEmpty);
    });

    test('crée une notification de type inconnu sans crash', () {
      final n = NotificationService.createTestNotification('autre');
      expect(n.id, isNotEmpty);
    });
  });
}
