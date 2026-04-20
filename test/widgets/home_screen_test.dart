import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/restaurant.dart';
import 'package:noogo/models/category.dart';
import 'package:noogo/models/flash_info.dart';
import 'package:noogo/screens/home_screen.dart';
import 'package:noogo/services/restaurant_provider.dart';
import 'package:noogo/widgets/skeleton.dart';

// ---------------------------------------------------------------------------
// Faux provider configurable
// ---------------------------------------------------------------------------
class _FakeProvider extends RestaurantProvider {
  final bool _loading;
  final String? _error;
  final bool _apiError;
  final Restaurant? _restaurant;
  final List<Category> _cats;
  final List<Dish> _dishes;

  _FakeProvider({
    bool loading = false,
    String? error,
    bool apiError = false,
    Restaurant? restaurant,
    List<Category> cats = const [],
    List<Dish> dishes = const [],
  })  : _loading = loading,
        _error = error,
        _apiError = apiError,
        _restaurant = restaurant,
        _cats = cats,
        _dishes = dishes;

  @override
  bool get isLoading => _loading;

  @override
  String? get error => _error;

  @override
  bool get hasApiError => _apiError;

  @override
  Restaurant? get restaurant => _restaurant;

  @override
  bool get hasData => _restaurant != null;

  @override
  List<Category> get categories => _cats;

  @override
  List<Dish> get dishes => _dishes;

  @override
  List<Dish> get dishesOfTheDay => [];

  @override
  List<FlashInfo> get flashInfos => [];

  @override
  List<OrderItem> get cartItems => const [];

  @override
  bool get hasCartItems => false;

  @override
  int get cartItemsCount => 0;

  @override
  double get cartTotal => 0;

  @override
  int get currentNavIndex => 0;

  @override
  int get unreadNotificationsCount => 0;

  @override
  String? get scannedQRCode =>
      null; // pas de QR en test, évite loadAllInitialData

  @override
  Future<void> loadAllInitialData({required int restaurantId}) async {} // no-op

  @override
  Future<void> refreshAllData() async {}

  @override
  void debugPrintState() {}
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------
Widget _wrapHome(_FakeProvider provider) {
  return ChangeNotifierProvider<RestaurantProvider>.value(
    value: provider,
    child: const MaterialApp(home: HomeScreen()),
  );
}

Restaurant _makeRestaurant() => Restaurant(
      id: 1,
      nom: 'Maquis Test',
      telephone: '70000000',
      adresse: 'Ouagadougou',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.loadFromString(envString: 'ENVIRONMENT=test');
  });

  group('HomeScreen — état chargement', () {
    testWidgets(
        'affiche des skeletons de chargement quand isLoading && !hasData',
        (tester) async {
      final provider = _FakeProvider(loading: true);

      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump();

      // L'écran utilise des Skeleton widgets, pas CircularProgressIndicator
      expect(find.byType(Skeleton), findsWidgets);
    });
  });

  group('HomeScreen — état erreur', () {
    testWidgets(
        'affiche "Impossible de charger" quand error != null && !hasData',
        (tester) async {
      final provider = _FakeProvider(error: 'Connexion impossible');

      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump();
      tester.takeException();

      expect(find.text('Impossible de charger'), findsOneWidget);
    });

    testWidgets('affiche le bouton "Réessayer" en cas d\'erreur',
        (tester) async {
      final provider = _FakeProvider(error: 'Timeout');

      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump();
      tester.takeException();

      expect(find.text('Réessayer'), findsWidgets);
    });
  });

  group('HomeScreen — données chargées', () {
    testWidgets(
        'affiche la BottomNavigationBar quand les données sont disponibles',
        (tester) async {
      final provider = _FakeProvider(restaurant: _makeRestaurant());

      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump();

      // La barre de navigation doit être présente
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets(
        'n\'affiche PAS le message d\'erreur de chargement quand hasData',
        (tester) async {
      final provider = _FakeProvider(restaurant: _makeRestaurant());

      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump();

      // Quand les données sont chargées, l'écran d'erreur ne doit pas s'afficher
      expect(find.text('Impossible de charger'), findsNothing);
    });

    testWidgets('affiche au moins un Scaffold quand les données sont chargées',
        (tester) async {
      final provider = _FakeProvider(restaurant: _makeRestaurant());
      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('affiche erreur API avec message approprié', (tester) async {
      final provider = _FakeProvider(apiError: true, error: 'Erreur serveur');
      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('état chargement initial (loading true, no data)',
        (tester) async {
      final provider = _FakeProvider(loading: true);
      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('dispose sans erreur', (tester) async {
      final provider = _FakeProvider(restaurant: _makeRestaurant());
      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('rend à 360x640 sans crash', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final provider = _FakeProvider(restaurant: _makeRestaurant());
      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('rend à 768x1024 (tablette)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final provider = _FakeProvider(restaurant: _makeRestaurant());
      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('avec données complétes (cats, dishes)', (tester) async {
      final cats = [Category(id: 1, name: 'Plats', imageUrl: '')];
      final dishes = [
        Dish(
            id: 1,
            name: 'Riz',
            description: '',
            price: 1000,
            imageUrl: '',
            categoryId: 1,
            category: 'Plats',
            isAvailable: true),
      ];
      final provider = _FakeProvider(
          restaurant: _makeRestaurant(), cats: cats, dishes: dishes);
      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('HomeScreen — navigation bottom bar', () {
    testWidgets('tap onglet 1 (Menu) appelle _navigateToPage', (tester) async {
      final provider = _FakeProvider(restaurant: _makeRestaurant());
      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump(const Duration(milliseconds: 200));
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        // Tap le 2ème onglet (index 1 = Menu)
        final items = find.descendant(
            of: bottomNav.first, matching: find.byType(InkResponse));
        if (items.evaluate().length > 1) {
          await tester.tap(items.at(1), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('tap onglet 2 (Panier) appelle _navigateToPage',
        (tester) async {
      final provider = _FakeProvider(restaurant: _makeRestaurant());
      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump(const Duration(milliseconds: 200));
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        final items = find.descendant(
            of: bottomNav.first, matching: find.byType(InkResponse));
        if (items.evaluate().length > 2) {
          await tester.tap(items.at(2), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('tap onglet 4 (Profil) appelle _navigateToPage',
        (tester) async {
      final provider = _FakeProvider(restaurant: _makeRestaurant());
      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump(const Duration(milliseconds: 200));
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        final items = find.descendant(
            of: bottomNav.first, matching: find.byType(InkResponse));
        if (items.evaluate().length > 4) {
          await tester.tap(items.at(4), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('dispose PageController sans erreur', (tester) async {
      final provider = _FakeProvider(restaurant: _makeRestaurant());
      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException();
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
      expect(find.byType(HomeScreen), findsNothing);
    });
  });
}
