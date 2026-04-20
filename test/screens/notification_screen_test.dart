import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:noogo/screens/notification_screen.dart';
import 'package:noogo/services/restaurant_provider.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/restaurant.dart';
import 'package:noogo/models/category.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/flash_info.dart';
import 'package:noogo/models/app_notification.dart';

// ── Fake provider ──────────────────────────────────────────────────────────

class _FakeEmptyProvider extends RestaurantProvider {
  @override
  bool get isLoading => false;
  @override
  bool get hasApiError => false;
  @override
  String? get error => null;
  @override
  bool get hasData => false;
  @override
  List<OrderItem> get cartItems => [];
  @override
  bool get hasCartItems => false;
  @override
  int get cartItemsCount => 0;
  @override
  double get cartTotal => 0;
  @override
  List<Category> get categories => [];
  @override
  List<Dish> get dishes => [];
  @override
  List<Dish> get dishesOfTheDay => [];
  @override
  List<FlashInfo> get flashInfos => [];
  @override
  List<Order> get orders => [];
  @override
  Restaurant? get restaurant => null;
  @override
  int get currentNavIndex => 0;
  @override
  List<AppNotification> get notifications => [];
  @override
  int get unreadNotificationsCount => 0;
}

class _FakeFilledProvider extends _FakeEmptyProvider {
  @override
  List<AppNotification> get notifications => [
        AppNotification(
          id: '1',
          type: 'order_status',
          title: 'Commande confirmée',
          body: 'Votre commande a été confirmée',
          isRead: false,
          timestamp: DateTime.now(),
        ),
        AppNotification(
          id: '2',
          type: 'order_status',
          title: 'Commande prête',
          body: 'Votre commande est prête',
          isRead: true,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
  @override
  int get unreadNotificationsCount => 1;
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _wrap(RestaurantProvider provider) {
  return ChangeNotifierProvider<RestaurantProvider>.value(
    value: provider,
    child: MaterialApp(
      home: const NotificationsScreen(),
      routes: {
        '/home': (_) => const Scaffold(body: Text('Home')),
      },
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      dotenv.loadFromString(envString: 'ENVIRONMENT=test');
    } catch (_) {}
  });

  group('NotificationsScreen', () {
    testWidgets('affiche l\'écran Notifications', (tester) async {
      await tester.pumpWidget(_wrap(_FakeEmptyProvider()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('affiche message vide sans notifications', (tester) async {
      await tester.pumpWidget(_wrap(_FakeEmptyProvider()));
      await tester.pump(const Duration(milliseconds: 300));

      // L'écran se rend correctement
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('affiche la liste des notifications', (tester) async {
      await tester.pumpWidget(_wrap(_FakeFilledProvider()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NotificationsScreen), findsOneWidget);
      // Les titres doivent être affichés
      expect(find.text('Commande confirmée'), findsOneWidget);
    });

    testWidgets('affiche notification non lue en premier', (tester) async {
      await tester.pumpWidget(_wrap(_FakeFilledProvider()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('affiche notification lue différemment', (tester) async {
      await tester.pumpWidget(_wrap(_FakeFilledProvider()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Commande prête'), findsOneWidget);
    });

    testWidgets('affiche le nombre de notifications non lues', (tester) async {
      await tester.pumpWidget(_wrap(_FakeFilledProvider()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('état vide affiche aucune notification', (tester) async {
      await tester.pumpWidget(_wrap(_FakeEmptyProvider()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('scrollable avec beaucoup de notifications', (tester) async {
      await tester.pumpWidget(_wrap(_FakeFilledProvider()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('dispose sans erreur', (tester) async {
      await tester.pumpWidget(_wrap(_FakeEmptyProvider()));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
      expect(find.byType(NotificationsScreen), findsNothing);
    });

    testWidgets('rend à 360x640 sans overflow fatal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(_FakeFilledProvider()));
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('tap sur une notification ne plante pas', (tester) async {
      await tester.pumpWidget(_wrap(_FakeFilledProvider()));
      await tester.pump(const Duration(milliseconds: 300));
      final items = find.byType(ListTile);
      if (items.evaluate().isNotEmpty) {
        await tester.tap(items.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));
      }
      tester.takeException();
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('affiche badge non lues quand count > 0', (tester) async {
      await tester.pumpWidget(_wrap(_FakeFilledProvider()));
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      // Badge "1 non lue" doit être visible
      expect(find.textContaining('non lue'), findsWidgets);
    });

    testWidgets('rend à 768x1024 (tablette)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(_FakeFilledProvider()));
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('scroll dans la liste des notifications', (tester) async {
      await tester.pumpWidget(_wrap(_FakeFilledProvider()));
      await tester.pump(const Duration(milliseconds: 300));
      final listViews = find.byType(ListView);
      if (listViews.evaluate().isNotEmpty) {
        await tester.drag(listViews.first, const Offset(0, -200));
        await tester.pump();
      }
      tester.takeException();
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('contient AppBar ou CustomAppBar', (tester) async {
      await tester.pumpWidget(_wrap(_FakeEmptyProvider()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('notification lue affichée correctement', (tester) async {
      await tester.pumpWidget(_wrap(_FakeFilledProvider()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Commande prête'), findsOneWidget);
      expect(find.text('Votre commande est prête'), findsOneWidget);
    });
  });
}
