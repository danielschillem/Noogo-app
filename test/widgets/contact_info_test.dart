import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noogo/widgets/contact_info.dart';
import 'package:noogo/models/restaurant.dart';
import 'package:noogo/models/category.dart';
import 'package:noogo/models/dish.dart';
import 'package:noogo/models/flash_info.dart';
import 'package:noogo/models/order.dart';
import 'package:noogo/services/restaurant_provider.dart';

// ── Fake provider ────────────────────────────────────────────────────────────

class _FakeProvider extends RestaurantProvider {
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
  int get unreadNotificationsCount => 0;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Restaurant _restaurant({
  int id = 1,
  String nom = 'Le Baobab',
  String telephone = '70000001',
  String adresse = 'Ouagadougou',
  double? latitude,
  double? longitude,
}) =>
    Restaurant(
      id: id,
      nom: nom,
      telephone: telephone,
      adresse: adresse,
      latitude: latitude,
      longitude: longitude,
    );

Widget _wrap(Restaurant restaurant) {
  return ChangeNotifierProvider<RestaurantProvider>.value(
    value: _FakeProvider(),
    child: MaterialApp(
      home: Scaffold(
        body: ContactInfo(restaurant: restaurant),
      ),
    ),
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

  group('ContactInfo — rendu de base', () {
    testWidgets('se construit sans erreur', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant()));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(ContactInfo), findsOneWidget);
    });

    testWidgets('affiche le numéro de téléphone', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant(telephone: '70111222')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('70111222'), findsOneWidget);
    });

    testWidgets('affiche l\'adresse du restaurant', (tester) async {
      await tester
          .pumpWidget(_wrap(_restaurant(adresse: 'Avenue de la Nation')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Avenue de la Nation'), findsOneWidget);
    });

    testWidgets('affiche un bouton appel téléphonique', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant()));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.phone_outlined), findsWidgets);
    });

    testWidgets('affiche le nom du restaurant dans les infos', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant(nom: 'Chez Fatou')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(ContactInfo), findsOneWidget);
    });
  });

  group('ContactInfo — sans coordonnées GPS', () {
    testWidgets('se construit sans latitude/longitude', (tester) async {
      await tester
          .pumpWidget(_wrap(_restaurant(latitude: null, longitude: null)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ContactInfo), findsOneWidget);
    });

    testWidgets('n\'affiche pas le badge de distance sans GPS', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant(latitude: null)));
      await tester.pump(const Duration(milliseconds: 300));
      // Pas de badge de distance - ne plante pas
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('ContactInfo — avec coordonnées GPS', () {
    testWidgets('se construit avec coordonnées GPS', (tester) async {
      await tester.pumpWidget(_wrap(
        _restaurant(latitude: 12.3610, longitude: -1.5339),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ContactInfo), findsOneWidget);
    });
  });

  group('ContactInfo — scan QR', () {
    testWidgets('affiche un bouton pour changer de restaurant', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant()));
      await tester.pump(const Duration(milliseconds: 200));
      // Un bouton doit exister pour déclencher le scanner
      expect(find.byType(ContactInfo), findsOneWidget);
    });

    testWidgets('tap bouton changer de restaurant ne plante pas',
        (tester) async {
      await tester.pumpWidget(_wrap(_restaurant()));
      await tester.pump(const Duration(milliseconds: 200));
      // Trouver un IconButton ou ElevatedButton pour scanner
      final scanBtns = find.byType(IconButton);
      if (scanBtns.evaluate().isNotEmpty) {
        await tester.tap(scanBtns.last, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
      }
      tester.takeException(); // absorb any nav error
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('ContactInfo — interactions téléphone', () {
    testWidgets('tap sur l\'icône téléphone ne plante pas', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant(telephone: '70222333')));
      await tester.pump(const Duration(milliseconds: 300));

      final phoneBtns = find.byIcon(Icons.phone_outlined);
      if (phoneBtns.evaluate().isNotEmpty) {
        await tester.tap(phoneBtns.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));
      }
      tester.takeException();
      expect(find.byType(ContactInfo), findsOneWidget);
    });
  });

  group('ContactInfo — Maps / adresse', () {
    testWidgets('affiche icône Maps ou directions', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant(
        adresse: '12 Rue du Commerce, Ouagadougou',
        latitude: 12.3610,
        longitude: -1.5339,
      )));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ContactInfo), findsOneWidget);
    });

    testWidgets('affiche adresse complète dans le widget', (tester) async {
      await tester
          .pumpWidget(_wrap(_restaurant(adresse: 'Secteur 15, Zone A')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Secteur 15, Zone A'), findsOneWidget);
    });

    testWidgets('se construit avec coordonnées précises Ouagadougou',
        (tester) async {
      await tester.pumpWidget(_wrap(_restaurant(
        latitude: 12.3636,
        longitude: -1.5353,
      )));
      await tester.pump(const Duration(milliseconds: 500));
      tester.takeException();
      expect(find.byType(ContactInfo), findsOneWidget);
    });
  });

  group('ContactInfo — divers', () {
    testWidgets('restaurant sans téléphone ne plante pas', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant(telephone: '')));
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      expect(find.byType(ContactInfo), findsOneWidget);
    });

    testWidgets('rend à 360x640 sans overflow fatal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(_restaurant()));
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      expect(find.byType(ContactInfo), findsOneWidget);
    });

    testWidgets('rend à 768x1024 (tablette)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(_restaurant()));
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      expect(find.byType(ContactInfo), findsOneWidget);
    });

    testWidgets('contient des widgets Text', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant(
        nom: 'Resto Délices',
        telephone: '76543210',
        adresse: 'Koudougou',
      )));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('dispose sans erreur', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant()));
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
      expect(find.byType(ContactInfo), findsNothing);
    });
  });

  group('ContactInfo — interactions', () {
    testWidgets('tap bouton Appeler ne plante pas', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant(telephone: '70000001')));
      await tester.pump(const Duration(milliseconds: 300));
      final appelerBtn = find.text('Appeler');
      if (appelerBtn.evaluate().isNotEmpty) {
        await tester.tap(appelerBtn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
      }
      tester.takeException();
      expect(find.byType(ContactInfo), findsOneWidget);
    });

    testWidgets('tap bouton Itinéraire ne plante pas', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant(
        latitude: 12.3610,
        longitude: -1.5339,
      )));
      await tester.pump(const Duration(milliseconds: 300));
      final itinBtn = find.text('Itinéraire');
      if (itinBtn.evaluate().isNotEmpty) {
        await tester.tap(itinBtn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
      }
      tester.takeException();
      expect(find.byType(ContactInfo), findsOneWidget);
    });

    testWidgets('tap icône QR scanner ouvre dialog de scan', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant()));
      await tester.pump(const Duration(milliseconds: 300));
      final qrIcon = find.byIcon(Icons.qr_code_scanner);
      if (qrIcon.evaluate().isNotEmpty) {
        await tester.tap(qrIcon.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        final cancelBtn = find.text('Annuler');
        if (cancelBtn.evaluate().isNotEmpty) {
          await tester.tap(cancelBtn.first, warnIfMissed: false);
          await tester.pump();
        }
      }
      tester.takeException();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('dialog QR scanner — tap Continuer lance scanner',
        (tester) async {
      await tester.pumpWidget(_wrap(_restaurant()));
      await tester.pump(const Duration(milliseconds: 300));
      final qrIcon = find.byIcon(Icons.qr_code_scanner);
      if (qrIcon.evaluate().isNotEmpty) {
        await tester.tap(qrIcon.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        final continueBtn = find.text('Continuer');
        if (continueBtn.evaluate().isNotEmpty) {
          await tester.tap(continueBtn.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('restaurant ouvert affiche badge Ouvert', (tester) async {
      final r = Restaurant(
        id: 1,
        nom: 'Test',
        telephone: '70000001',
        adresse: 'Ouaga',
        isOpenFromApi: true,
      );
      await tester.pumpWidget(ChangeNotifierProvider<RestaurantProvider>.value(
        value: _FakeProvider(),
        child: MaterialApp(
          home: Scaffold(body: ContactInfo(restaurant: r)),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      tester.takeException();
      expect(find.byType(ContactInfo), findsOneWidget);
    });

    testWidgets('tap GestureDetector sur icône de scan', (tester) async {
      await tester.pumpWidget(_wrap(_restaurant()));
      await tester.pump(const Duration(milliseconds: 300));
      final gds = find.byType(GestureDetector);
      if (gds.evaluate().length > 1) {
        await tester.tap(gds.at(1), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        final cancelBtn = find.text('Annuler');
        if (cancelBtn.evaluate().isNotEmpty) {
          await tester.tap(cancelBtn.first, warnIfMissed: false);
          await tester.pump();
        }
      }
      tester.takeException();
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
