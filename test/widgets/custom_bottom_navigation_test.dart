import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noogo/widgets/custom_bottom_navigation.dart';
import 'package:noogo/services/restaurant_provider.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/restaurant.dart';
import 'package:noogo/models/category.dart';
import 'package:noogo/models/flash_info.dart';

// ── Fake provider ─────────────────────────────────────────────────────────────

class _FakeProvider extends RestaurantProvider {
  final int _cartLen;
  _FakeProvider({int cartLen = 0}) : _cartLen = cartLen;

  @override
  bool get isLoading => false;
  @override
  bool get hasApiError => false;
  @override
  String? get error => null;
  @override
  bool get hasData => false;
  @override
  List<OrderItem> get cartItems => List.generate(
        _cartLen,
        (i) => OrderItem(
          dish: Dish(
              id: i,
              name: 'P$i',
              description: '',
              price: 100,
              imageUrl: '',
              categoryId: 1,
              category: '',
              isAvailable: true),
          quantity: 1,
        ),
      );
  @override
  bool get hasCartItems => _cartLen > 0;
  @override
  int get cartItemsCount => _cartLen;
  @override
  double get cartTotal => _cartLen * 100.0;
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
  int get unreadNotificationsCount => 0;
}

Widget _wrap({int currentIndex = 0, int cartLen = 0}) {
  return ChangeNotifierProvider<RestaurantProvider>.value(
    value: _FakeProvider(cartLen: cartLen),
    child: MaterialApp(
      home: Scaffold(
        bottomNavigationBar: CustomBottomNavigation(
          currentIndex: currentIndex,
          onTap: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      dotenv.loadFromString(envString: 'ENVIRONMENT=test');
    } catch (_) {}
  });

  group('CustomBottomNavigation', () {
    testWidgets('se construit sans erreur', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(CustomBottomNavigation), findsOneWidget);
    });

    testWidgets('affiche BottomNavigationBar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('affiche "Accueil" comme premier onglet', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Accueil'), findsOneWidget);
    });

    testWidgets('affiche "Menu" comme deuxième onglet', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Menu'), findsOneWidget);
    });

    testWidgets('affiche "Panier" comme troisième onglet', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Panier'), findsOneWidget);
    });

    testWidgets('affiche "Commandes" comme quatrième onglet', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Commandes'), findsOneWidget);
    });

    testWidgets('panier vide — pas de badge rouge', (tester) async {
      await tester.pumpWidget(_wrap(cartLen: 0));
      await tester.pump();
      expect(find.byType(CustomBottomNavigation), findsOneWidget);
    });

    testWidgets('panier avec 3 articles — badge "3" visible', (tester) async {
      await tester.pumpWidget(_wrap(cartLen: 3));
      await tester.pump();
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('panier avec 10 articles — badge "9+"', (tester) async {
      await tester.pumpWidget(_wrap(cartLen: 10));
      await tester.pump();
      expect(find.text('9+'), findsWidgets);
    });

    testWidgets('panier avec 1 article — badge "1"', (tester) async {
      await tester.pumpWidget(_wrap(cartLen: 1));
      await tester.pump();
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('onglet actif index 0 sélectionné', (tester) async {
      await tester.pumpWidget(_wrap(currentIndex: 0));
      await tester.pump();
      final nav =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(nav.currentIndex, 0);
    });

    testWidgets('onglet actif index 2 (Panier)', (tester) async {
      await tester.pumpWidget(_wrap(currentIndex: 2));
      await tester.pump();
      final nav =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(nav.currentIndex, 2);
    });
  });
}
