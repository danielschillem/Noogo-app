import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/restaurant.dart';
import 'package:noogo/models/category.dart';
import 'package:noogo/models/flash_info.dart';
import 'package:noogo/screens/cart_screen.dart';
import 'package:noogo/services/restaurant_provider.dart';

// ---------------------------------------------------------------------------
// Faux provider de test (ne fait aucun appel réseau ni disque)
// ---------------------------------------------------------------------------
class _FakeProvider extends RestaurantProvider {
  final List<OrderItem> _fakeCart;
  final Restaurant? _fakeRestaurant;

  _FakeProvider({List<OrderItem> cart = const [], Restaurant? restaurant})
      : _fakeCart = cart,
        _fakeRestaurant = restaurant;

  @override
  Restaurant? get restaurant => _fakeRestaurant;

  @override
  bool get isLoading => false;

  @override
  bool get hasApiError => false;

  @override
  String? get error => null;

  @override
  bool get hasData => _fakeRestaurant != null;

  @override
  List<OrderItem> get cartItems => List.unmodifiable(_fakeCart);

  @override
  bool get hasCartItems => _fakeCart.isNotEmpty;

  @override
  int get cartItemsCount => _fakeCart.fold(0, (s, i) => s + i.quantity);

  @override
  double get cartTotal => _fakeCart.fold(0.0, (s, i) => s + i.totalPrice);

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
  int get unreadNotificationsCount => 0;

  @override
  Future<void> refreshAllData() async {}

  @override
  void debugPrintState() {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Widget _wrapCart(_FakeProvider provider) {
  return ChangeNotifierProvider<RestaurantProvider>.value(
    value: provider,
    child: const MaterialApp(home: CartScreen()),
  );
}

Dish _makeDish(
        {int id = 1, String name = 'Riz sauce tomate', double price = 1500}) =>
    Dish(
      id: id,
      name: name,
      description: 'Un plat délicieux',
      price: price,
      imageUrl: '', // pas d'image en test
      categoryId: 1,
      category: 'Plats',
      isAvailable: true,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialiser dotenv avec un contenu vide (flutter_dotenv v6 API)
    dotenv.loadFromString(envString: 'ENVIRONMENT=test');
  });

  group('CartScreen — panier vide', () {
    testWidgets('affiche le message "Votre panier est vide"', (tester) async {
      await tester.pumpWidget(_wrapCart(_FakeProvider()));
      await tester.pump(); // settle animations

      expect(find.text('Votre panier est vide'), findsOneWidget);
    });

    testWidgets('affiche le bouton "Voir le menu"', (tester) async {
      await tester.pumpWidget(_wrapCart(_FakeProvider()));
      await tester.pump();

      expect(find.text('Voir le menu'), findsOneWidget);
    });

    testWidgets('affiche l\'icône de panier vide', (tester) async {
      await tester.pumpWidget(_wrapCart(_FakeProvider()));
      await tester.pump();

      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });
  });

  group('CartScreen — panier avec articles', () {
    testWidgets('affiche le nom du plat présent dans le panier',
        (tester) async {
      final dish = _makeDish(name: 'Poulet braisé');
      final cart = [OrderItem(dish: dish, quantity: 2)];

      await tester.pumpWidget(_wrapCart(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle();

      expect(find.text('Poulet braisé'), findsOneWidget);
    });

    testWidgets('affiche la quantité de l\'article', (tester) async {
      final dish = _makeDish(name: 'Thiébou Dieun');
      final cart = [OrderItem(dish: dish, quantity: 3)];

      await tester.pumpWidget(_wrapCart(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle();

      // La quantité "3" doit apparaître dans l'UI du panier
      expect(find.text('3'), findsWidgets);
    });

    testWidgets(
        'N\'affiche PAS le message "panier vide" quand il y a des articles',
        (tester) async {
      final cart = [OrderItem(dish: _makeDish(), quantity: 1)];

      await tester.pumpWidget(_wrapCart(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle();

      expect(find.text('Votre panier est vide'), findsNothing);
    });
  });
}
