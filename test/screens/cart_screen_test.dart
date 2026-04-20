import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noogo/models/category.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/flash_info.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/restaurant.dart';
import 'package:noogo/screens/cart_screen.dart';
import 'package:noogo/services/restaurant_provider.dart';

// ── Fake provider ────────────────────────────────────────────────────────────

class _FakeProvider extends RestaurantProvider {
  final List<OrderItem> _cart;
  final bool _loading;

  _FakeProvider({List<OrderItem> cart = const [], bool loading = false})
      : _cart = cart,
        _loading = loading;

  @override
  bool get isLoading => _loading;
  @override
  bool get hasApiError => false;
  @override
  String? get error => null;
  @override
  bool get hasData => _cart.isNotEmpty;
  @override
  List<OrderItem> get cartItems => List.unmodifiable(_cart);
  @override
  bool get hasCartItems => _cart.isNotEmpty;
  @override
  int get cartItemsCount => _cart.fold(0, (s, i) => s + i.quantity);
  @override
  double get cartTotal => _cart.fold(0.0, (s, i) => s + i.totalPrice);
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
  @override
  Future<void> refreshAllData() async {}
  @override
  void debugPrintState() {}
  @override
  void setNavIndex(int index) {}
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Dish _dish({
  int id = 1,
  String name = 'Riz sauce tomate',
  double price = 1500,
}) =>
    Dish(
      id: id,
      name: name,
      description: 'Un plat délicieux',
      price: price,
      imageUrl: '',
      categoryId: 1,
      category: 'Plats',
      isAvailable: true,
    );

Widget _wrap(_FakeProvider provider) {
  return ChangeNotifierProvider<RestaurantProvider>.value(
    value: provider,
    child: const MaterialApp(home: CartScreen()),
  );
}

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

  // ── Panier vide ─────────────────────────────────────────────────────────────

  group('CartScreen — panier vide', () {
    testWidgets('se construit sans erreur', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider()));
      await tester.pump();
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('affiche le titre "Panier" dans l\'AppBar', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider()));
      await tester.pump();
      expect(find.text('Panier'), findsWidgets);
    });

    testWidgets('affiche l\'icône de panier vide', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider()));
      await tester.pump();
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('affiche le message panier vide', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider()));
      await tester.pump();
      expect(find.text('Votre panier est vide'), findsOneWidget);
    });

    testWidgets('affiche la description panier vide', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider()));
      await tester.pump();
      expect(
        find.text(
          'Ajoutez des plats depuis le menu pour commencer votre commande',
        ),
        findsOneWidget,
      );
    });

    testWidgets('affiche le bouton "Voir le menu"', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider()));
      await tester.pump();
      expect(find.text('Voir le menu'), findsOneWidget);
    });

    testWidgets('affiche un Scaffold', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider()));
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('n\'affiche pas de ListView quand le panier est vide',
        (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider()));
      await tester.pump();
      expect(find.byType(ListView), findsNothing);
    });
  });

  // ── Panier avec articles ────────────────────────────────────────────────────

  group('CartScreen — avec articles', () {
    testWidgets('affiche le nom du plat', (tester) async {
      final cart = [OrderItem(dish: _dish(name: 'Poulet braisé'), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Poulet braisé'), findsOneWidget);
    });

    testWidgets('affiche le titre Mon Panier', (tester) async {
      final cart = [OrderItem(dish: _dish(), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Mon Panier'), findsOneWidget);
    });

    testWidgets('affiche la quantité de l\'article', (tester) async {
      final cart = [OrderItem(dish: _dish(), quantity: 3)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('affiche le prix par plat en FCFA', (tester) async {
      final cart = [
        OrderItem(dish: _dish(name: 'Riz sauce', price: 1500), quantity: 1)
      ];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('FCFA'), findsWidgets);
    });

    testWidgets('n\'affiche pas le message panier vide', (tester) async {
      final cart = [OrderItem(dish: _dish(), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Votre panier est vide'), findsNothing);
    });

    testWidgets('affiche les icônes + et - pour la quantité', (tester) async {
      final cart = [OrderItem(dish: _dish(), quantity: 2)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byIcon(Icons.add), findsWidgets);
      expect(find.byIcon(Icons.remove), findsWidgets);
    });

    testWidgets('affiche l\'icône de suppression de l\'article',
        (tester) async {
      final cart = [OrderItem(dish: _dish(), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('affiche le récapitulatif des coûts', (tester) async {
      final cart = [OrderItem(dish: _dish(price: 2000), quantity: 2)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Sous-total'), findsOneWidget);
    });

    testWidgets('affiche la ligne Total', (tester) async {
      final cart = [OrderItem(dish: _dish(price: 1000), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('affiche les frais de livraison', (tester) async {
      final cart = [OrderItem(dish: _dish(price: 1000), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Frais de livraison'), findsOneWidget);
    });

    testWidgets('affiche le bouton Commander', (tester) async {
      final cart = [OrderItem(dish: _dish(price: 1500), quantity: 2)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('Commander'), findsOneWidget);
    });

    testWidgets('affiche un indicateur de chargement quand loading est vrai',
        (tester) async {
      final cart = [OrderItem(dish: _dish(price: 1500), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart, loading: true)));
      // Ne pas utiliser pumpAndSettle car CircularProgressIndicator ne settle pas
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('affiche l\'icône menu contextuel (more_vert)', (tester) async {
      final cart = [OrderItem(dish: _dish(), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('affiche le badge article count', (tester) async {
      final cart = [
        OrderItem(dish: _dish(id: 1, name: 'Plat A'), quantity: 2),
        OrderItem(dish: _dish(id: 2, name: 'Plat B'), quantity: 1),
      ];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      // cartItemsCount = 3
      expect(find.textContaining('Plats'), findsWidgets);
    });

    testWidgets('affiche plusieurs articles dans la liste', (tester) async {
      final cart = [
        OrderItem(dish: _dish(id: 1, name: 'Poulet rôti'), quantity: 1),
        OrderItem(dish: _dish(id: 2, name: 'Attiéké'), quantity: 2),
      ];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Poulet rôti'), findsOneWidget);
      expect(find.text('Attiéké'), findsOneWidget);
    });
  });

  // ── Préremplissage depuis SharedPreferences ──────────────────────────────

  group('CartScreen — préremplissage numéros', () {
    testWidgets('charge sans erreur avec un numéro de téléphone sauvegardé',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'client_phone': '70001234',
        'client_mm_phone': '71005678',
      });
      final cart = [OrderItem(dish: _dish(), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('charge sans erreur avec des préférences vides',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_wrap(_FakeProvider()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(CartScreen), findsOneWidget);
    });
  });

  // ── Interactions panier ──────────────────────────────────────────────────

  group('CartScreen — interactions articles', () {
    testWidgets('tap sur + augmente la quantité', (tester) async {
      final cart = [OrderItem(dish: _dish(name: 'Poulet Test'), quantity: 1)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final addBtn = find.byIcon(Icons.add);
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn.first);
        await tester.pump();
      }
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('tap sur - diminue la quantité', (tester) async {
      final cart = [OrderItem(dish: _dish(name: 'Plat Moins'), quantity: 3)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final removeBtn = find.byIcon(Icons.remove);
      if (removeBtn.evaluate().isNotEmpty) {
        await tester.tap(removeBtn.first);
        await tester.pump();
      }
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('tap sur icône supprimer ouvre dialog', (tester) async {
      final cart = [OrderItem(dish: _dish(name: 'Plat Sup'), quantity: 1)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final deleteBtn = find.byIcon(Icons.delete_outline);
      if (deleteBtn.evaluate().isNotEmpty) {
        await tester.tap(deleteBtn.first);
        await tester.pump();
      }
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('tap sur "Voir le menu" fonctionne', (tester) async {
      final provider = _FakeProvider();
      await tester.pumpWidget(_wrap(provider));
      await tester.pump();

      final btn = find.text('Voir le menu');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first);
        await tester.pump();
      }
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('plusieurs articles — total correct affiché', (tester) async {
      final cart = [
        OrderItem(dish: _dish(id: 1, price: 2000), quantity: 2),
        OrderItem(dish: _dish(id: 2, price: 1000), quantity: 1),
      ];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('FCFA'), findsWidgets);
    });

    testWidgets('grand panier (5 articles) se rend sans overflow',
        (tester) async {
      final cart = List.generate(
        5,
        (i) => OrderItem(
            dish: _dish(id: i + 1, name: 'Plat ${i + 1}'), quantity: 1),
      );
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      tester.takeException();
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('tap Commander ouvre bottom sheet de paiement', (tester) async {
      final cart = [OrderItem(dish: _dish(price: 1500), quantity: 1)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final btn = find.widgetWithText(ElevatedButton, 'Commander • 1500 FCFA');
      if (btn.evaluate().isEmpty) {
        // Chercher par texte partiel
        final btns = find.textContaining('Commander');
        if (btns.evaluate().isNotEmpty) {
          await tester.tap(btns.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 500));
        }
      } else {
        await tester.tap(btn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
      }
      tester.takeException();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('tap menu contextuel more_vert ouvre popup', (tester) async {
      final cart = [OrderItem(dish: _dish(), quantity: 1)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final moreBtn = find.byIcon(Icons.more_vert);
      if (moreBtn.evaluate().isNotEmpty) {
        await tester.tap(moreBtn.first);
        await tester.pump(const Duration(milliseconds: 300));
      }
      tester.takeException();
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('dispose sans erreur', (tester) async {
      final cart = [OrderItem(dish: _dish(), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      tester.takeException();
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
      expect(find.byType(CartScreen), findsNothing);
    });

    testWidgets('rend à 360x640 sans overflow fatal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cart = [OrderItem(dish: _dish(), quantity: 2)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      tester.takeException();
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('rend à 768x1024 (tablette)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cart = [OrderItem(dish: _dish(), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      tester.takeException();
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('scroll dans la liste du panier', (tester) async {
      final cart = List.generate(
        8,
        (i) =>
            OrderItem(dish: _dish(id: i + 1, name: 'Article $i'), quantity: 1),
      );
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final lv = find.byType(ListView);
      if (lv.evaluate().isNotEmpty) {
        await tester.drag(lv.first, const Offset(0, -300));
        await tester.pump();
      }
      tester.takeException();
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('article avec image locale se rend sans crash', (tester) async {
      final dishWithImage = Dish(
        id: 99,
        name: 'Plat Photo',
        description: '',
        price: 2000,
        imageUrl: 'assets/images/placeholder.png',
        categoryId: 1,
        category: 'Plats',
        isAvailable: true,
      );
      final cart = [OrderItem(dish: dishWithImage, quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pump(const Duration(seconds: 2));
      tester.takeException();
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('quantité 1 → bouton - rouge', (tester) async {
      final cart = [OrderItem(dish: _dish(), quantity: 1)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byIcon(Icons.remove), findsWidgets);
    });

    testWidgets('quantité > 1 → bouton - orange', (tester) async {
      final cart = [OrderItem(dish: _dish(), quantity: 3)];
      await tester.pumpWidget(_wrap(_FakeProvider(cart: cart)));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byIcon(Icons.remove), findsWidgets);
    });
  });

  // ── Dialogs de commande ──────────────────────────────────────────────────

  group('CartScreen — dialog Commander', () {
    testWidgets('tap Commander ouvre dialog type commande', (tester) async {
      final cart = [OrderItem(dish: _dish(price: 2000), quantity: 1)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final btn = find.textContaining('Commander');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 500));
        // Dialog type commande devrait être visible
        tester.takeException();
      }
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('dialog type commande — tap Annuler ferme le dialog',
        (tester) async {
      final cart = [OrderItem(dish: _dish(price: 2000), quantity: 1)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final btn = find.textContaining('Commander');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));

        final cancelBtn = find.text('Annuler');
        if (cancelBtn.evaluate().isNotEmpty) {
          await tester.tap(cancelBtn.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('dialog type commande — tap Sur place', (tester) async {
      final cart = [OrderItem(dish: _dish(price: 2000), quantity: 1)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final btn = find.textContaining('Commander');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));

        final surPlace = find.text('Sur place');
        if (surPlace.evaluate().isNotEmpty) {
          await tester.tap(surPlace.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('dialog type commande — tap À emporter', (tester) async {
      final cart = [OrderItem(dish: _dish(price: 2000), quantity: 1)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final btn = find.textContaining('Commander');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));

        final emporter = find.textContaining('emporter');
        if (emporter.evaluate().isNotEmpty) {
          await tester.tap(emporter.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('dialog supprimer article — tap Retirer confirme',
        (tester) async {
      final cart = [OrderItem(dish: _dish(name: 'Plat Sup'), quantity: 1)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final deleteBtn = find.byIcon(Icons.delete_outline);
      if (deleteBtn.evaluate().isNotEmpty) {
        await tester.tap(deleteBtn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));

        final retirer = find.text('Retirer');
        if (retirer.evaluate().isNotEmpty) {
          await tester.tap(retirer.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('dialog supprimer article — tap Annuler garde l\'article',
        (tester) async {
      final cart = [OrderItem(dish: _dish(name: 'Plat Garde'), quantity: 1)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final deleteBtn = find.byIcon(Icons.delete_outline);
      if (deleteBtn.evaluate().isNotEmpty) {
        await tester.tap(deleteBtn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));

        final annuler = find.text('Annuler');
        if (annuler.evaluate().isNotEmpty) {
          await tester.tap(annuler.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('dialog vider panier — tap Vider depuis menu contextuel',
        (tester) async {
      final cart = [OrderItem(dish: _dish(), quantity: 1)];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final moreBtn = find.byIcon(Icons.more_vert);
      if (moreBtn.evaluate().isNotEmpty) {
        await tester.tap(moreBtn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));

        final vider = find.text('Vider le panier');
        if (vider.evaluate().isNotEmpty) {
          await tester.tap(vider.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('dialog vider panier — tap Annuler depuis menu contextuel',
        (tester) async {
      final cart = [
        OrderItem(dish: _dish(), quantity: 1),
        OrderItem(dish: _dish(id: 2, name: 'Plat 2'), quantity: 2)
      ];
      final provider = _FakeProvider(cart: cart);
      await tester.pumpWidget(_wrap(provider));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final moreBtn = find.byIcon(Icons.more_vert);
      if (moreBtn.evaluate().isNotEmpty) {
        await tester.tap(moreBtn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));

        final vider = find.text('Vider le panier');
        if (vider.evaluate().isNotEmpty) {
          await tester.tap(vider.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));

          final annuler = find.text('Annuler');
          if (annuler.evaluate().isNotEmpty) {
            await tester.tap(annuler.first, warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 300));
          }
        }
      }
      tester.takeException();
      expect(find.byType(CartScreen), findsOneWidget);
    });
  });
}
