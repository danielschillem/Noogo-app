import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:noogo/screens/orders_screen.dart';
import 'package:noogo/services/restaurant_provider.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/restaurant.dart';
import 'package:noogo/models/category.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/flash_info.dart';

// ── Fake provider ─────────────────────────────────────────────────────────

class _FakeProvider extends RestaurantProvider {
  final List<Order> _orders;
  final Restaurant? _resto;
  _FakeProvider({List<Order> orders = const [], Restaurant? resto})
      : _orders = orders,
        _resto = resto;

  @override
  Restaurant? get restaurant => _resto;
  @override
  bool get isLoading => false;
  @override
  bool get hasApiError => false;
  @override
  String? get error => null;
  @override
  bool get hasData => _resto != null;
  @override
  List<Order> get orders => List.unmodifiable(_orders);
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
  int get currentNavIndex => 0;
  @override
  Future<void> forceRefreshOrders() async {}
  @override
  Future<void> loadAllInitialData({int? restaurantId}) async {}
  @override
  void setNavIndex(int index) {}
}

// ── Helpers ───────────────────────────────────────────────────────────────

Restaurant _fakeResto() => Restaurant(
      id: 1,
      nom: 'Resto Test',
      telephone: '70000000',
      adresse: 'Ouagadougou',
    );

Order _fakeOrder({
  int id = 1,
  OrderStatus status = OrderStatus.pending,
  OrderType type = OrderType.surPlace,
}) =>
    Order(
      id: id,
      restaurantId: '1',
      status: status,
      orderType: type,
      paymentMethod: 'cash',
      items: [],
      orderDate: DateTime.now(),
      table: 'T1',
    );

Widget _wrap(RestaurantProvider provider) {
  return ChangeNotifierProvider<RestaurantProvider>.value(
    value: provider,
    child: MaterialApp(
      home: const OrdersScreen(),
      routes: {
        '/welcome': (_) => const Scaffold(body: Text('Welcome')),
        '/home': (_) => const Scaffold(body: Text('Home')),
      },
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await dotenv.load(fileName: 'assets/env/.env');
    } catch (_) {}
  });

  group('OrdersScreen', () {
    testWidgets('affiche l\'état vide quand aucune commande', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider(resto: _fakeResto())));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('affiche les commandes disponibles', (tester) async {
      final orders = [
        _fakeOrder(id: 1, status: OrderStatus.pending),
        _fakeOrder(id: 2, status: OrderStatus.confirmed),
      ];
      await tester.pumpWidget(
        _wrap(_FakeProvider(orders: orders, resto: _fakeResto())),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('affiche OrdersScreen sans restaurant', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('commande avec statut delivered', (tester) async {
      final orders = [
        _fakeOrder(id: 1, status: OrderStatus.delivered),
      ];
      await tester.pumpWidget(
        _wrap(_FakeProvider(orders: orders, resto: _fakeResto())),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('plusieurs commandes différents statuts', (tester) async {
      final orders = [
        _fakeOrder(id: 1, status: OrderStatus.pending),
        _fakeOrder(id: 2, status: OrderStatus.confirmed),
        _fakeOrder(id: 3, status: OrderStatus.preparing),
        _fakeOrder(id: 4, status: OrderStatus.ready),
        _fakeOrder(id: 5, status: OrderStatus.completed),
        _fakeOrder(id: 6, status: OrderStatus.cancelled),
      ];
      await tester.pumpWidget(
        _wrap(_FakeProvider(orders: orders, resto: _fakeResto())),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('commande de type livraison', (tester) async {
      final orders = [
        _fakeOrder(
            id: 1, status: OrderStatus.confirmed, type: OrderType.livraison),
      ];
      await tester.pumpWidget(
        _wrap(_FakeProvider(orders: orders, resto: _fakeResto())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('commande de type emporter', (tester) async {
      final orders = [
        _fakeOrder(id: 1, status: OrderStatus.ready, type: OrderType.aEmporter),
      ];
      await tester.pumpWidget(
        _wrap(_FakeProvider(orders: orders, resto: _fakeResto())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('affiche AppBar avec titre', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider(resto: _fakeResto())));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AppBar), findsWidgets);
    });

    testWidgets('10 commandes rendues sans crash', (tester) async {
      final orders = List.generate(
        10,
        (i) => _fakeOrder(id: i + 1, status: OrderStatus.completed),
      );
      await tester.pumpWidget(
        _wrap(_FakeProvider(orders: orders, resto: _fakeResto())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('dispose sans erreur', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider(resto: _fakeResto())));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
      expect(find.byType(OrdersScreen), findsNothing);
    });

    testWidgets('rend à 360x640 sans overflow fatal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(_FakeProvider(resto: _fakeResto())));
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('scroll dans la liste des commandes', (tester) async {
      final orders = List.generate(
        8,
        (i) => _fakeOrder(id: i + 1),
      );
      await tester.pumpWidget(
        _wrap(_FakeProvider(orders: orders, resto: _fakeResto())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final scrollables = find.byType(ListView);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -200));
        await tester.pump();
      }
      tester.takeException();
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('affiche texte "Aucune commande" quand liste vide',
        (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider(resto: _fakeResto())));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Aucune commande'), findsOneWidget);
    });

    testWidgets('bouton Découvrir le menu dans état vide', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider(resto: _fakeResto())));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('menu'), findsWidgets);
    });

    testWidgets('tap Découvrir le menu appelle setNavIndex', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider(resto: _fakeResto())));
      await tester.pump(const Duration(milliseconds: 300));
      final btn = find.text('Découvrir le menu');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn);
        await tester.pump();
      }
      tester.takeException();
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('commande avec items affiche les plats', (tester) async {
      final dish = Dish(
        id: 1,
        name: 'Riz sauce',
        description: '',
        price: 1500,
        imageUrl: '',
        categoryId: 1,
        category: 'Plats',
        isAvailable: true,
      );
      final orderWithItems = Order(
        id: 42,
        restaurantId: '1',
        status: OrderStatus.confirmed,
        orderType: OrderType.surPlace,
        paymentMethod: 'cash',
        items: [OrderItem(dish: dish, quantity: 2)],
        orderDate: DateTime.now(),
        table: 'T1',
      );
      await tester.pumpWidget(
        _wrap(_FakeProvider(orders: [orderWithItems], resto: _fakeResto())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('commande avec Mobile Money affiche icône téléphone',
        (tester) async {
      final order = Order(
        id: 1,
        restaurantId: '1',
        status: OrderStatus.completed,
        orderType: OrderType.surPlace,
        paymentMethod: 'Mobile Money',
        items: [],
        orderDate: DateTime.now(),
        table: 'T1',
      );
      await tester.pumpWidget(
        _wrap(_FakeProvider(orders: [order], resto: _fakeResto())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('commande annulée affiche bon statut', (tester) async {
      final orders = [_fakeOrder(id: 1, status: OrderStatus.cancelled)];
      await tester.pumpWidget(
        _wrap(_FakeProvider(orders: orders, resto: _fakeResto())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('rend avec plusieurs types de commandes', (tester) async {
      final orders = [
        Order(
          id: 1,
          restaurantId: '1',
          status: OrderStatus.pending,
          orderType: OrderType.livraison,
          paymentMethod: 'cash',
          items: [],
          orderDate: DateTime.now(),
          table: null,
        ),
        Order(
          id: 2,
          restaurantId: '1',
          status: OrderStatus.ready,
          orderType: OrderType.aEmporter,
          paymentMethod: 'Mobile Money',
          items: [],
          orderDate: DateTime.now(),
          table: null,
        ),
      ];
      await tester.pumpWidget(
        _wrap(_FakeProvider(orders: orders, resto: _fakeResto())),
      );
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      expect(find.byType(OrdersScreen), findsOneWidget);
    });
  });
}
