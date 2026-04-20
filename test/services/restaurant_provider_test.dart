// ignore_for_file: avoid_print

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noogo/services/restaurant_provider.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/app_notification.dart';
import 'package:noogo/config/demo_data.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Dish _dish({
  int id = 1,
  String name = 'Riz sauce',
  double price = 1500,
  bool available = true,
}) =>
    Dish(
      id: id,
      name: name,
      description: 'Délicieux',
      price: price,
      imageUrl: '',
      categoryId: 1,
      category: 'Plats',
      isAvailable: available,
    );

AppNotification _notif({
  String id = 'n1',
  String title = 'Test notif',
  String body = 'Un test',
  bool isRead = false,
}) =>
    AppNotification(
      id: id,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: isRead,
      type: 'order',
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

  // ── Initialisation ─────────────────────────────────────────────────────────

  group('RestaurantProvider — état initial', () {
    test('état initial par défaut', () {
      final p = RestaurantProvider();
      expect(p.isLoading, isFalse);
      expect(p.hasApiError, isFalse);
      expect(p.error, isNull);
      expect(p.restaurant, isNull);
      expect(p.hasData, isFalse);
      expect(p.cartItems, isEmpty);
      expect(p.cartItemsCount, 0);
      expect(p.cartTotal, 0.0);
      expect(p.hasCartItems, isFalse);
      expect(p.dishes, isEmpty);
      expect(p.categories, isEmpty);
      expect(p.orders, isEmpty);
      expect(p.flashInfos, isEmpty);
      expect(p.currentNavIndex, 0);
      expect(p.isOffline, isFalse);
      expect(p.notifications, isEmpty);
      expect(p.unreadNotificationsCount, 0);
      expect(p.orderSubmitState, OrderSubmitState.idle);
      expect(p.isSubmittingOrder, isFalse);
      expect(p.orderSubmitError, isNull);
      expect(p.isRealtimeConnected, isFalse);
      expect(p.scannedQRCode, isNull);
      p.dispose();
    });

    test('cartSummary retourne "Panier vide" si vide', () {
      final p = RestaurantProvider();
      expect(p.cartSummary, 'Panier vide');
      p.dispose();
    });

    test('availableDishes retourne vide si dishes vide', () {
      final p = RestaurantProvider();
      expect(p.availableDishes, isEmpty);
      p.dispose();
    });
  });

  // ── Navigation ─────────────────────────────────────────────────────────────

  group('RestaurantProvider — navigation', () {
    test('setNavIndex met à jour currentNavIndex', () {
      final p = RestaurantProvider();
      p.setNavIndex(2);
      expect(p.currentNavIndex, 2);
      p.setNavIndex(0);
      expect(p.currentNavIndex, 0);
      p.dispose();
    });

    test('setNavIndex notifie les listeners', () {
      final p = RestaurantProvider();
      int calls = 0;
      p.addListener(() => calls++);
      p.setNavIndex(3);
      expect(calls, 1);
      p.dispose();
    });
  });

  // ── Panier — addToCart ─────────────────────────────────────────────────────

  group('RestaurantProvider — addToCart', () {
    test('ajoute un plat au panier', () {
      final p = RestaurantProvider();
      p.addToCart(_dish(id: 1, name: 'Poulet'));
      expect(p.cartItems.length, 1);
      expect(p.cartItems.first.dish.name, 'Poulet');
      expect(p.cartItems.first.quantity, 1);
      p.dispose();
    });

    test('addToCart avec quantity personnalisé', () {
      final p = RestaurantProvider();
      p.addToCart(_dish(id: 1), quantity: 3);
      expect(p.cartItems.first.quantity, 3);
      p.dispose();
    });

    test('addToCart cumule la quantité si même plat', () {
      final p = RestaurantProvider();
      p.addToCart(_dish(id: 1), quantity: 2);
      p.addToCart(_dish(id: 1), quantity: 1);
      expect(p.cartItems.length, 1);
      expect(p.cartItems.first.quantity, 3);
      p.dispose();
    });

    test('addToCart ajoute un second plat distinct', () {
      final p = RestaurantProvider();
      p.addToCart(_dish(id: 1, name: 'Riz'));
      p.addToCart(_dish(id: 2, name: 'Poulet'));
      expect(p.cartItems.length, 2);
      p.dispose();
    });

    test('cartItemsCount reflète les quantités', () {
      final p = RestaurantProvider();
      p.addToCart(_dish(id: 1), quantity: 2);
      p.addToCart(_dish(id: 2), quantity: 3);
      expect(p.cartItemsCount, 5);
      p.dispose();
    });

    test('cartTotal calcule correctement', () {
      final p = RestaurantProvider();
      p.addToCart(_dish(id: 1, price: 1000), quantity: 2);
      p.addToCart(_dish(id: 2, price: 500), quantity: 1);
      expect(p.cartTotal, 2500.0);
      p.dispose();
    });

    test('hasCartItems est true après ajout', () {
      final p = RestaurantProvider();
      p.addToCart(_dish(id: 1));
      expect(p.hasCartItems, isTrue);
      p.dispose();
    });

    test('cartSummary liste les plats et totaux', () {
      final p = RestaurantProvider();
      p.addToCart(_dish(id: 1, name: 'Riz', price: 1000), quantity: 2);
      final summary = p.cartSummary;
      expect(summary, contains('Riz'));
      expect(summary, contains('x2'));
      p.dispose();
    });

    test('addToCart notifie les listeners', () {
      final p = RestaurantProvider();
      int calls = 0;
      p.addListener(() => calls++);
      p.addToCart(_dish());
      expect(calls, 1);
      p.dispose();
    });
  });

  // ── Panier — removeFromCart ────────────────────────────────────────────────

  group('RestaurantProvider — removeFromCart', () {
    test('supprime un plat du panier', () {
      final p = RestaurantProvider();
      final dish = _dish(id: 1);
      p.addToCart(dish);
      p.removeFromCart(dish);
      expect(p.cartItems, isEmpty);
      p.dispose();
    });

    test('ne plante pas si plat inexistant', () {
      final p = RestaurantProvider();
      expect(() => p.removeFromCart(_dish(id: 99)), returnsNormally);
      p.dispose();
    });

    test('removeFromCart ne supprime pas les autres plats', () {
      final p = RestaurantProvider();
      final d1 = _dish(id: 1);
      final d2 = _dish(id: 2);
      p.addToCart(d1);
      p.addToCart(d2);
      p.removeFromCart(d1);
      expect(p.cartItems.length, 1);
      expect(p.cartItems.first.dish.id, 2);
      p.dispose();
    });

    test('removeFromCart notifie les listeners', () {
      final p = RestaurantProvider();
      final d = _dish();
      p.addToCart(d);
      int calls = 0;
      p.addListener(() => calls++);
      p.removeFromCart(d);
      expect(calls, 1);
      p.dispose();
    });
  });

  // ── Panier — updateCartItemQuantity ───────────────────────────────────────

  group('RestaurantProvider — updateCartItemQuantity', () {
    test('met à jour la quantité', () {
      final p = RestaurantProvider();
      final d = _dish(id: 1);
      p.addToCart(d, quantity: 1);
      p.updateCartItemQuantity(d, 5);
      expect(p.cartItems.first.quantity, 5);
      p.dispose();
    });

    test('supprime l\'article si quantité = 0', () {
      final p = RestaurantProvider();
      final d = _dish(id: 1);
      p.addToCart(d, quantity: 2);
      p.updateCartItemQuantity(d, 0);
      expect(p.cartItems, isEmpty);
      p.dispose();
    });

    test('supprime l\'article si quantité négative', () {
      final p = RestaurantProvider();
      final d = _dish(id: 1);
      p.addToCart(d, quantity: 2);
      p.updateCartItemQuantity(d, -1);
      expect(p.cartItems, isEmpty);
      p.dispose();
    });

    test('ne fait rien si plat inexistant', () {
      final p = RestaurantProvider();
      expect(() => p.updateCartItemQuantity(_dish(id: 99), 5), returnsNormally);
      p.dispose();
    });

    test('updateCartItemQuantity notifie les listeners', () {
      final p = RestaurantProvider();
      final d = _dish(id: 1);
      p.addToCart(d);
      int calls = 0;
      p.addListener(() => calls++);
      p.updateCartItemQuantity(d, 3);
      expect(calls, 1);
      p.dispose();
    });
  });

  // ── Panier — clearCart ────────────────────────────────────────────────────

  group('RestaurantProvider — clearCart', () {
    test('vide le panier', () {
      final p = RestaurantProvider();
      p.addToCart(_dish(id: 1));
      p.addToCart(_dish(id: 2));
      p.clearCart();
      expect(p.cartItems, isEmpty);
      expect(p.cartTotal, 0.0);
      expect(p.cartItemsCount, 0);
      p.dispose();
    });

    test('clearCart notifie les listeners', () {
      final p = RestaurantProvider();
      p.addToCart(_dish());
      int calls = 0;
      p.addListener(() => calls++);
      p.clearCart();
      expect(calls, 1);
      p.dispose();
    });
  });

  // ── Filtres ───────────────────────────────────────────────────────────────

  group('RestaurantProvider — filterDishesByCategory', () {
    test('retourne tous les plats si categoryId est null', () {
      final p = RestaurantProvider();
      // dishes est vide mais la méthode ne plante pas
      final result = p.filterDishesByCategory(null);
      expect(result, isEmpty);
      p.dispose();
    });

    test('retourne tous les plats si categoryId = 0', () {
      final p = RestaurantProvider();
      final result = p.filterDishesByCategory(0);
      expect(result, isEmpty);
      p.dispose();
    });

    test('loadDishes retourne la liste des dishes', () {
      final p = RestaurantProvider();
      final result = p.loadDishes();
      expect(result, isA<List<Dish>>());
      p.dispose();
    });
  });

  // ── Données de démo ───────────────────────────────────────────────────────

  group('RestaurantProvider — loadDemoData', () {
    test('charge les données de démo', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      expect(p.restaurant, isNotNull);
      expect(p.restaurant!.nom, isNotEmpty);
      expect(p.dishes, isNotEmpty);
      expect(p.categories, isNotEmpty);
      expect(p.hasData, isTrue);
      p.dispose();
    });

    test('filterDishesByCategory fonctionne après loadDemoData', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      final allDishes = p.filterDishesByCategory(null);
      expect(allDishes.length, p.dishes.length);
      p.dispose();
    });

    test('availableDishes retourne les plats disponibles', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      final available = p.availableDishes;
      for (final d in available) {
        expect(d.isAvailable, isTrue);
      }
      p.dispose();
    });

    test('dishesOfTheDay est un sous-ensemble de dishes', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      final dayDishes = p.dishesOfTheDay;
      for (final d in dayDishes) {
        expect(d.isDishOfTheDay, isTrue);
      }
      p.dispose();
    });

    test('loadDemoData notifie les listeners', () {
      final p = RestaurantProvider();
      int calls = 0;
      p.addListener(() => calls++);
      p.loadDemoData();
      expect(calls, greaterThan(0));
      p.dispose();
    });

    test('favoriteDishes vide avant chargement des favoris', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      expect(p.favoriteDishes, isEmpty);
      p.dispose();
    });

    test('isFavoriteDish retourne false pour un plat non favori', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      expect(p.isFavoriteDish(999), isFalse);
      p.dispose();
    });

    test('favoriteDishIds est en lecture seule', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      final ids = p.favoriteDishIds;
      expect(ids, isA<Set<int>>());
      p.dispose();
    });
  });

  // ── Machine d'état commande ───────────────────────────────────────────────

  group('RestaurantProvider — orderSubmitState', () {
    test('état initial est idle', () {
      final p = RestaurantProvider();
      expect(p.orderSubmitState, OrderSubmitState.idle);
      expect(p.isSubmittingOrder, isFalse);
      expect(p.orderSubmitError, isNull);
      p.dispose();
    });

    test('resetOrderSubmitState remet à idle', () {
      final p = RestaurantProvider();
      p.setLoading(true); // Use setLoading to trigger some state
      p.resetOrderSubmitState();
      expect(p.orderSubmitState, OrderSubmitState.idle);
      expect(p.orderSubmitError, isNull);
      p.dispose();
    });

    test('resetOrderSubmitState notifie les listeners', () {
      final p = RestaurantProvider();
      int calls = 0;
      p.addListener(() => calls++);
      p.resetOrderSubmitState();
      expect(calls, 1);
      p.dispose();
    });
  });

  // ── setLoading ────────────────────────────────────────────────────────────

  group('RestaurantProvider — setLoading', () {
    test('setLoading(true) met isLoading à true', () {
      final p = RestaurantProvider();
      p.setLoading(true);
      expect(p.isLoading, isTrue);
      p.dispose();
    });

    test('setLoading(false) met isLoading à false', () {
      final p = RestaurantProvider();
      p.setLoading(true);
      p.setLoading(false);
      expect(p.isLoading, isFalse);
      p.dispose();
    });

    test('setLoading notifie les listeners', () {
      final p = RestaurantProvider();
      int calls = 0;
      p.addListener(() => calls++);
      p.setLoading(true);
      expect(calls, 1);
      p.dispose();
    });
  });

  // ── clearQRCode ───────────────────────────────────────────────────────────

  group('RestaurantProvider — clearQRCode', () {
    test('clearQRCode remet scannedQRCode à null', () {
      final p = RestaurantProvider();
      p.clearQRCode();
      expect(p.scannedQRCode, isNull);
      p.dispose();
    });
  });

  // ── debugPrintState ───────────────────────────────────────────────────────

  group('RestaurantProvider — debugPrintState', () {
    test('debugPrintState ne plante pas', () {
      final p = RestaurantProvider();
      expect(() => p.debugPrintState(), returnsNormally);
      p.dispose();
    });

    test('debugPrintState après loadDemoData ne plante pas', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      expect(() => p.debugPrintState(), returnsNormally);
      p.dispose();
    });
  });

  // ── resetAllData ──────────────────────────────────────────────────────────

  group('RestaurantProvider — resetAllData', () {
    test('resetAllData remet les données à zéro', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      p.addToCart(_dish(id: 1));
      p.resetAllData();
      expect(p.isLoading, isFalse);
      expect(p.cartItems, isEmpty);
      p.dispose();
    });

    test('resetAllData ne plante pas', () {
      final p = RestaurantProvider();
      expect(() => p.resetAllData(), returnsNormally);
      p.dispose();
    });
  });

  // ── Notifications ─────────────────────────────────────────────────────────

  group('RestaurantProvider — notifications (SharedPreferences)', () {
    test('loadNotifications retourne liste vide si rien en cache', () async {
      final p = RestaurantProvider();
      await p.loadNotifications();
      expect(p.notifications, isEmpty);
      p.dispose();
    });

    test('addNotification ajoute une notification', () async {
      final p = RestaurantProvider();
      await p.addNotification(_notif(id: 'n1', title: 'Bonjour'));
      expect(p.notifications.length, 1);
      expect(p.notifications.first.title, 'Bonjour');
      p.dispose();
    });

    test('addNotification ne duplique pas la même notification', () async {
      final p = RestaurantProvider();
      await p.addNotification(_notif(id: 'n1'));
      await p.addNotification(_notif(id: 'n1'));
      expect(p.notifications.length, 1);
      p.dispose();
    });

    test('unreadNotificationsCount est correct', () async {
      final p = RestaurantProvider();
      await p.addNotification(_notif(id: 'n1', isRead: false));
      await p.addNotification(_notif(id: 'n2', isRead: false));
      expect(p.unreadNotificationsCount, 2);
      p.dispose();
    });

    test('markNotificationAsRead met la notification à lue', () async {
      final p = RestaurantProvider();
      await p.addNotification(_notif(id: 'r1', isRead: false));
      await p.markNotificationAsRead('r1');
      expect(p.unreadNotificationsCount, 0);
      p.dispose();
    });

    test('markAllNotificationsAsRead marque toutes comme lues', () async {
      final p = RestaurantProvider();
      await p.addNotification(_notif(id: 'a1', isRead: false));
      await p.addNotification(_notif(id: 'a2', isRead: false));
      await p.markAllNotificationsAsRead();
      expect(p.unreadNotificationsCount, 0);
      p.dispose();
    });

    test('deleteNotification supprime une notification', () async {
      final p = RestaurantProvider();
      await p.addNotification(_notif(id: 'd1', title: 'À supprimer'));
      await p.addNotification(_notif(id: 'd2', title: 'À garder'));
      await p.deleteNotification('d1');
      expect(p.notifications.any((n) => n.id == 'd1'), isFalse);
      expect(p.notifications.any((n) => n.id == 'd2'), isTrue);
      p.dispose();
    });

    test('clearAllNotifications vide toutes les notifications', () async {
      final p = RestaurantProvider();
      await p.addNotification(_notif(id: 'c1'));
      await p.addNotification(_notif(id: 'c2'));
      await p.clearAllNotifications();
      expect(p.notifications, isEmpty);
      p.dispose();
    });

    test('createTestNotification crée une notification de test', () async {
      final p = RestaurantProvider();
      await p.createTestNotification('order');
      expect(p.notifications.isNotEmpty, isTrue);
      p.dispose();
    });
  });

  // ── Commande — createOrderNotification ───────────────────────────────────

  group('RestaurantProvider — createOrderNotification', () {
    test('createOrderNotification crée une notification', () async {
      final p = RestaurantProvider();
      final order = Order(
        id: 42,
        items: [OrderItem(dish: _dish(), quantity: 1)],
        status: OrderStatus.confirmed,
        orderDate: DateTime.now(),
        paymentMethod: 'cash',
        orderType: OrderType.surPlace,
      );
      await p.createOrderNotification(order);
      expect(p.notifications.isNotEmpty, isTrue);
      p.dispose();
    });
  });

  // ── Favoris ───────────────────────────────────────────────────────────────

  group('RestaurantProvider — favorites (SharedPreferences)', () {
    test('loadFavorites retourne vide si rien en cache', () async {
      final p = RestaurantProvider();
      await p.loadFavorites();
      expect(p.favoriteDishIds, isEmpty);
      p.dispose();
    });

    test('toggleFavoriteDish ajoute un favori', () async {
      final p = RestaurantProvider();
      p.loadDemoData();
      final firstDishId = p.dishes.first.id;
      await p.toggleFavoriteDish(firstDishId);
      expect(p.isFavoriteDish(firstDishId), isTrue);
      p.dispose();
    });

    test('toggleFavoriteDish retire un favori existant', () async {
      final p = RestaurantProvider();
      p.loadDemoData();
      final firstDishId = p.dishes.first.id;
      await p.toggleFavoriteDish(firstDishId); // ajoute
      await p.toggleFavoriteDish(firstDishId); // retire
      expect(p.isFavoriteDish(firstDishId), isFalse);
      p.dispose();
    });

    test('favoriteDishes ne liste que les plats chargés et favoris', () async {
      final p = RestaurantProvider();
      p.loadDemoData();
      final firstDish = p.dishes.first;
      await p.toggleFavoriteDish(firstDish.id);
      expect(p.favoriteDishes.any((d) => d.id == firstDish.id), isTrue);
      p.dispose();
    });
  });

  // ── Gestion du QR / validateRestaurantQRCode ─────────────────────────────

  group('RestaurantProvider — validateRestaurantQRCode erreurs', () {
    test('QR invalide lève une exception', () async {
      final p = RestaurantProvider();
      await expectLater(
        () => p.validateRestaurantQRCode('qr_invalide'),
        throwsException,
      );
      expect(p.hasApiError, isTrue);
      p.dispose();
    });

    test('QR invalide met hasApiError à true', () async {
      final p = RestaurantProvider();
      try {
        await p.validateRestaurantQRCode('');
      } catch (_) {}
      expect(p.hasApiError, isTrue);
      p.dispose();
    });

    test('QR invalide met error', () async {
      final p = RestaurantProvider();
      try {
        await p.validateRestaurantQRCode('https://invalid.url/123');
      } catch (_) {}
      expect(p.error, isNotNull);
      p.dispose();
    });
  });

  // ── Données de démo — filtres avancés ────────────────────────────────────

  group('RestaurantProvider — filterDishesByCategory après chargement démo',
      () {
    test('filtre par catégorie existante', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      // DemoData has categories - take first one
      if (p.categories.isNotEmpty) {
        final catId = p.categories.first.id;
        final filtered = p.filterDishesByCategory(catId);
        for (final d in filtered) {
          expect(d.categoryId, catId);
        }
      }
      p.dispose();
    });

    test('filtre par catégorie 0 retourne tous les plats', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      final all = p.filterDishesByCategory(0);
      expect(all.length, p.dishes.length);
      p.dispose();
    });

    test('filtre par catégorie nulle retourne tous les plats', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      final all = p.filterDishesByCategory(null);
      expect(all.length, p.dishes.length);
      p.dispose();
    });
  });

  // ── addToCart après demo ──────────────────────────────────────────────────

  group('RestaurantProvider — cart avec données démo', () {
    test('ajoute un plat de démo au panier', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      final dish = p.dishes.first;
      p.addToCart(dish, quantity: 2);
      expect(p.cartItemsCount, 2);
      expect(p.hasCartItems, isTrue);
      expect(p.cartTotal, dish.price * 2);
      p.dispose();
    });

    test('cartSummary avec un plat de démo', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      final dish = p.dishes.first;
      p.addToCart(dish, quantity: 1);
      final summary = p.cartSummary;
      expect(summary, contains(dish.name));
      p.dispose();
    });
  });

  // ── dispose ───────────────────────────────────────────────────────────────

  group('RestaurantProvider — dispose', () {
    test('dispose ne plante pas', () {
      final p = RestaurantProvider();
      expect(() => p.dispose(), returnsNormally);
    });

    test('dispose après loadDemoData ne plante pas', () {
      final p = RestaurantProvider();
      p.loadDemoData();
      p.addToCart(_dish());
      expect(() => p.dispose(), returnsNormally);
    });
  });

  // ── DemoData — données statiques ──────────────────────────────────────────

  group('DemoData', () {
    test('DemoData.restaurant est valide', () {
      final r = DemoData.restaurant;
      expect(r.id, isPositive);
      expect(r.nom, isNotEmpty);
    });

    test('DemoData.categories est non vide', () {
      expect(DemoData.categories, isNotEmpty);
    });

    test('DemoData.dishes est non vide', () {
      expect(DemoData.dishes, isNotEmpty);
    });

    test('DemoData.flashInfos est non vide', () {
      expect(DemoData.flashInfos, isNotEmpty);
    });

    test('tous les plats de DemoData ont un nom', () {
      for (final d in DemoData.dishes) {
        expect(d.name, isNotEmpty);
      }
    });

    test('tous les plats de DemoData ont un prix positif', () {
      for (final d in DemoData.dishes) {
        expect(d.price, isPositive);
      }
    });
  });
}
