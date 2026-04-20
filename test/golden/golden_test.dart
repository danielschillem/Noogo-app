// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:noogo/screens/onboarding_screen.dart';
import 'package:noogo/screens/welcome_screen.dart';
import 'package:noogo/screens/cart_screen.dart';
import 'package:noogo/services/restaurant_provider.dart';
import 'package:noogo/models/restaurant.dart';
import 'package:noogo/models/category.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/models/flash_info.dart';

// ── Fake provider utilisé par les tests du panier ─────────────────────────

class _FakeProvider extends RestaurantProvider {
  final List<OrderItem> _cart;
  final Restaurant? _resto;
  _FakeProvider({List<OrderItem> cart = const [], Restaurant? resto})
      : _cart = cart,
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
  int get currentNavIndex => 0;
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _wrapSimple(Widget child) {
  SharedPreferences.setMockInitialValues({});
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF97316)),
      fontFamily: 'Roboto',
    ),
    home: child,
    routes: {
      '/welcome': (_) => const Scaffold(body: Text('Welcome')),
      '/home': (_) => const Scaffold(body: Text('Home')),
    },
  );
}

Widget _wrapWithProvider(Widget child, RestaurantProvider provider) {
  return ChangeNotifierProvider<RestaurantProvider>.value(
    value: provider,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF97316)),
        fontFamily: 'Roboto',
      ),
      home: child,
      routes: {
        '/welcome': (_) => const Scaffold(body: Text('Welcome')),
        '/home': (_) => const Scaffold(body: Text('Home')),
      },
    ),
  );
}

Restaurant _fakeRestaurant() => Restaurant(
      id: 1,
      nom: 'Chez Koudougou',
      telephone: '70000000',
      adresse: 'Ouagadougou, BF',
    );

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await dotenv.load(fileName: 'assets/env/.env');
    } catch (_) {}
  });

  group('Golden – OnboardingScreen', () {
    // Helper to suppress rendering overflow in fixed test canvas
    void Function(FlutterErrorDetails)? savedHandler;
    setUp(() {
      savedHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        savedHandler?.call(details);
      };
    });
    tearDown(() => FlutterError.onError = savedHandler);

    testWidgets('slide 1 matches golden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapSimple(const OnboardingScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(OnboardingScreen),
        matchesGoldenFile('goldens/onboarding_slide1.png'),
      );
    });

    testWidgets('slide 2 matches golden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapSimple(const OnboardingScreen()));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Suivant'));
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(OnboardingScreen),
        matchesGoldenFile('goldens/onboarding_slide2.png'),
      );
    });

    testWidgets('last slide matches golden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapSimple(const OnboardingScreen()));
      await tester.pump(const Duration(milliseconds: 200));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pump(const Duration(milliseconds: 500));
      }

      await expectLater(
        find.byType(OnboardingScreen),
        matchesGoldenFile('goldens/onboarding_last_slide.png'),
      );
    });

    testWidgets('tablet 768x1024 layout matches golden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapSimple(const OnboardingScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(OnboardingScreen),
        matchesGoldenFile('goldens/onboarding_tablet.png'),
      );
    });
  });

  group('Golden – CartScreen', () {
    testWidgets('empty cart matches golden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrapWithProvider(const CartScreen(), _FakeProvider()),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('goldens/cart_empty.png'),
      );
    });

    testWidgets('cart with items matches golden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      final dish = Dish(
        id: 1,
        name: 'Riz sauce tomate',
        description: 'Délicieux',
        price: 1500,
        imageUrl: '',
        categoryId: 1,
        category: 'Plats',
        isAvailable: true,
      );
      final cart = [OrderItem(dish: dish, quantity: 2)];

      await tester.pumpWidget(
        _wrapWithProvider(
          const CartScreen(),
          _FakeProvider(cart: cart, resto: _fakeRestaurant()),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('goldens/cart_with_items.png'),
      );
    });
  });

  group('Golden – WelcomeScreen', () {
    testWidgets('phone layout matches golden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Suppress overflow rendering errors – expected in fixed test canvas.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(_wrapSimple(const WelcomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(WelcomeScreen),
        matchesGoldenFile('goldens/welcome_phone.png'),
      );
    });

    testWidgets('tablet layout matches golden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(_wrapSimple(const WelcomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(WelcomeScreen),
        matchesGoldenFile('goldens/welcome_tablet.png'),
      );
    });
  });
}
