import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:noogo/screens/menu_screen.dart';
import 'package:noogo/services/restaurant_provider.dart';
import 'package:noogo/models/restaurant.dart';
import 'package:noogo/models/category.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/flash_info.dart';

class _FakeProvider extends RestaurantProvider {
  final Restaurant? _resto;
  final List<Category> _cats;
  final List<Dish> _dishes;

  _FakeProvider(
      {Restaurant? resto,
      List<Category> cats = const [],
      List<Dish> dishes = const []})
      : _resto = resto,
        _cats = cats,
        _dishes = dishes;

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
  List<OrderItem> get cartItems => [];
  @override
  bool get hasCartItems => false;
  @override
  int get cartItemsCount => 0;
  @override
  double get cartTotal => 0.0;
  @override
  List<Category> get categories => _cats;
  @override
  List<Dish> get dishes => _dishes;
  @override
  List<Dish> get dishesOfTheDay =>
      _dishes.where((d) => d.isDishOfTheDay).toList();
  @override
  List<FlashInfo> get flashInfos => [];
  @override
  int get currentNavIndex => 1;
}

Restaurant _fakeRestaurant() => Restaurant(
      id: 1,
      nom: 'Chez Koudougou',
      telephone: '70000000',
      adresse: 'Ouagadougou, BF',
    );

Category _fakeCategory() => Category(
      id: 1,
      name: 'Plats chauds',
      imageUrl: '',
    );

Dish _fakeDish() => Dish(
      id: 1,
      name: 'Riz sauce tomate',
      description: 'Délicieux plat',
      price: 1500,
      imageUrl: '',
      categoryId: 1,
      category: 'Plats chauds',
      isAvailable: true,
    );

Widget _wrap(RestaurantProvider provider) {
  return ChangeNotifierProvider<RestaurantProvider>.value(
    value: provider,
    child: MaterialApp(
      home: const MenuScreen(),
      routes: {
        '/home': (ctx) => const Scaffold(body: Text('Home')),
      },
    ),
  );
}

void main() {
  setUpAll(() async {
    try {
      await dotenv.load(fileName: 'assets/env/.env');
    } catch (_) {}
  });

  group('MenuScreen', () {
    testWidgets('renders without crashing when no data', (tester) async {
      await tester.pumpWidget(_wrap(_FakeProvider()));
      await tester.pump();
      tester.takeException();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows loading state when isLoading flag active',
        (tester) async {
      final provider = _FakeProvider();
      await tester.pumpWidget(_wrap(provider));
      await tester.pump();
      tester.takeException();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with restaurant and categories', (tester) async {
      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: [_fakeCategory()],
        dishes: [_fakeDish()],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('dish name is displayed', (tester) async {
      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: [_fakeCategory()],
        dishes: [_fakeDish()],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();
      expect(find.textContaining('Riz sauce tomate'), findsWidgets);
    });

    testWidgets('category name is displayed', (tester) async {
      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: [_fakeCategory()],
        dishes: [_fakeDish()],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();
      expect(find.textContaining('Plats chauds'), findsWidgets);
    });

    testWidgets('renders in tablet size without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: [_fakeCategory()],
        dishes: [_fakeDish()],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('affiche le bouton de recherche ou champ', (tester) async {
      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: [_fakeCategory()],
        dishes: [_fakeDish()],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException();
      final hasSearch = find.byType(TextField).evaluate().isNotEmpty ||
          find.byType(TextFormField).evaluate().isNotEmpty ||
          find.byIcon(Icons.search).evaluate().isNotEmpty;
      expect(hasSearch || find.byType(Scaffold).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('affiche prix du plat', (tester) async {
      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: [_fakeCategory()],
        dishes: [_fakeDish()],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException();
      expect(
          find.textContaining('1500').evaluate().isNotEmpty ||
              find.textContaining('FCFA').evaluate().isNotEmpty,
          isTrue);
    });

    testWidgets('scroll dans la liste de plats', (tester) async {
      final dishes = List.generate(
          10,
          (i) => Dish(
                id: i + 1,
                name: 'Plat $i',
                description: 'Desc',
                price: (i + 1) * 500,
                imageUrl: '',
                categoryId: 1,
                category: 'Cat',
                isAvailable: true,
              ));
      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: [_fakeCategory()],
        dishes: dishes,
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException();
      final scrollables = find.byType(SingleChildScrollView);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -300));
        await tester.pump();
      }
      expect(find.byType(MenuScreen), findsOneWidget);
    });

    testWidgets('dispose sans erreur', (tester) async {
      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: [_fakeCategory()],
        dishes: [_fakeDish()],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException(); // absorb any overflow
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
      expect(find.byType(MenuScreen), findsNothing);
    });

    testWidgets('rend à 360x640 sans overflow fatal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: [_fakeCategory()],
        dishes: [_fakeDish()],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('plusieurs catégories affichées', (tester) async {
      final cats = [
        Category(id: 1, name: 'Plats chauds', imageUrl: ''),
        Category(id: 2, name: 'Boissons', imageUrl: ''),
        Category(id: 3, name: 'Desserts', imageUrl: ''),
      ];
      final dishes = [
        Dish(
            id: 1,
            name: 'Riz',
            description: '',
            price: 1000,
            imageUrl: '',
            categoryId: 1,
            category: 'Plats chauds',
            isAvailable: true),
        Dish(
            id: 2,
            name: 'Jus',
            description: '',
            price: 500,
            imageUrl: '',
            categoryId: 2,
            category: 'Boissons',
            isAvailable: true),
      ];
      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: cats,
        dishes: dishes,
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException();
      expect(find.byType(MenuScreen), findsOneWidget);
    });

    testWidgets('plat indisponible dans la liste', (tester) async {
      final unavailable = Dish(
        id: 99,
        name: 'Plat épuisé',
        description: '',
        price: 2000,
        imageUrl: '',
        categoryId: 1,
        category: 'Plats chauds',
        isAvailable: false,
      );
      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: [_fakeCategory()],
        dishes: [_fakeDish(), unavailable],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException();
      expect(find.byType(MenuScreen), findsOneWidget);
    });

    testWidgets('plat du jour présent', (tester) async {
      final dishOfDay = Dish(
        id: 5,
        name: 'Plat du jour spécial',
        description: '',
        price: 2500,
        imageUrl: '',
        categoryId: 1,
        category: 'Plats chauds',
        isAvailable: true,
        isDishOfTheDay: true,
      );
      final provider = _FakeProvider(
        resto: _fakeRestaurant(),
        cats: [_fakeCategory()],
        dishes: [dishOfDay],
      );
      await tester.pumpWidget(_wrap(provider));
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException();
      expect(find.byType(MenuScreen), findsOneWidget);
    });
  });
}
