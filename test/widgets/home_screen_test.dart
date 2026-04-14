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
        'affiche un indicateur de chargement quand isLoading && !hasData',
        (tester) async {
      final provider = _FakeProvider(loading: true);

      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HomeScreen — état erreur', () {
    testWidgets(
        'affiche "Erreur de chargement" quand error != null && !hasData',
        (tester) async {
      final provider = _FakeProvider(error: 'Connexion impossible');

      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump();

      expect(find.text('Erreur de chargement'), findsOneWidget);
    });

    testWidgets('affiche le bouton "Réessayer" en cas d\'erreur',
        (tester) async {
      final provider = _FakeProvider(error: 'Timeout');

      await tester.pumpWidget(_wrapHome(provider));
      await tester.pump();

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
      expect(find.text('Erreur de chargement'), findsNothing);
    });
  });
}
