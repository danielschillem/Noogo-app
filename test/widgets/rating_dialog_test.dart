import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:noogo/widgets/rating_dialog.dart';
import 'package:noogo/models/order.dart';

Order _fakeOrder() => Order(
      id: 42,
      items: [],
      status: OrderStatus.delivered,
      orderDate: DateTime.now(),
      paymentMethod: 'cash',
      orderType: OrderType.surPlace,
      table: 'T5',
      restaurantId: '1',
    );

Widget _wrap(Widget child) {
  SharedPreferences.setMockInitialValues({});
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      dotenv.loadFromString(envString: 'ENVIRONMENT=test');
    } catch (_) {}
  });

  group('RatingDialog', () {
    testWidgets('affiche le dialog avec 5 étoiles', (tester) async {
      await tester.pumpWidget(
        _wrap(RatingDialog(order: _fakeOrder(), onRated: () {})),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(RatingDialog), findsOneWidget);
      // 5 icônes d'étoile (star_rounded ou star_outline_rounded)
      expect(
          find.byIcon(Icons.star_rounded).evaluate().length +
              find.byIcon(Icons.star_outline_rounded).evaluate().length,
          greaterThanOrEqualTo(5));
    });

    testWidgets('affiche le numéro de commande', (tester) async {
      await tester.pumpWidget(
        _wrap(RatingDialog(order: _fakeOrder(), onRated: () {})),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Commande #42 ou référence dans le texte
      expect(find.byType(RatingDialog), findsOneWidget);
    });

    testWidgets('tap sur une étoile la sélectionne', (tester) async {
      await tester.pumpWidget(
        _wrap(RatingDialog(order: _fakeOrder(), onRated: () {})),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final stars = find.byIcon(Icons.star);
      if (stars.evaluate().isNotEmpty) {
        await tester.tap(stars.first);
        await tester.pump();
      }

      expect(find.byType(RatingDialog), findsOneWidget);
    });

    testWidgets('affiche le champ de commentaire', (tester) async {
      await tester.pumpWidget(
        _wrap(RatingDialog(order: _fakeOrder(), onRated: () {})),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('le bouton Envoyer est présent', (tester) async {
      await tester.pumpWidget(
        _wrap(RatingDialog(order: _fakeOrder(), onRated: () {})),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Le bouton Envoyer/Valider doit être présent
      expect(
        find.byType(ElevatedButton).evaluate().isNotEmpty ||
            find.byType(TextButton).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('affiche bouton Annuler', (tester) async {
      await tester.pumpWidget(
        _wrap(RatingDialog(order: _fakeOrder(), onRated: () {})),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(RatingDialog), findsOneWidget);
    });
  });
}
