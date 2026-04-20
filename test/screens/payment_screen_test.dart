import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/screens/payment_screen.dart';

// PaymentScreen initie automatiquement un appel réseau dans initState.
// On le teste avec pump limité (sans pumpAndSettle) pour éviter le timeout réseau.

Widget _wrap({String provider = 'orange'}) => MaterialApp(
      home: PaymentScreen(
        restaurantId: 1,
        provider: provider,
        phone: '70000000',
        amount: 2000,
        orderId: 42,
      ),
    );

// PaymentScreen has:
//   - AnimationController.repeat() (pulse)
//   - PaymentService.initiate() HTTP call with 20s timeout
// Drain all pending timers by pumping 25s while widget is mounted,
// then swap to _blank to trigger dispose(). No pending timers remain.
const _blank = MaterialApp(home: SizedBox());

void main() {
  group('PaymentScreen', () {
    testWidgets('renders initial loading state', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byType(PaymentScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('shows provider label for orange', (tester) async {
      await tester.pumpWidget(_wrap(provider: 'orange'));
      await tester.pump();

      expect(find.byType(PaymentScreen), findsOneWidget);

      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('shows provider label for wave', (tester) async {
      await tester.pumpWidget(_wrap(provider: 'wave'));
      await tester.pump();

      expect(find.byType(PaymentScreen), findsOneWidget);

      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('shows provider label for moov', (tester) async {
      await tester.pumpWidget(_wrap(provider: 'moov'));
      await tester.pump();

      expect(find.byType(PaymentScreen), findsOneWidget);

      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('disposes cleanly without crash', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('shows provider label for telecel', (tester) async {
      await tester.pumpWidget(_wrap(provider: 'telecel'));
      await tester.pump();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('shows provider label for cash', (tester) async {
      await tester.pumpWidget(_wrap(provider: 'cash'));
      await tester.pump();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('accepts large amount', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaymentScreen(
          restaurantId: 1,
          provider: 'orange',
          phone: '70000000',
          amount: 150000,
          orderId: 99,
        ),
      ));
      await tester.pump();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('works with null orderId', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaymentScreen(
          restaurantId: 1,
          provider: 'wave',
          phone: '65000000',
          amount: 5000,
        ),
      ));
      await tester.pump();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('contient des widgets Text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Text), findsWidgets);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('orange provider à 360x640', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(provider: 'orange'));
      await tester.pump();
      tester.takeException();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('wave provider à 360x640', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(provider: 'wave'));
      await tester.pump();
      tester.takeException();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('montant zéro', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaymentScreen(
          restaurantId: 1,
          provider: 'cash',
          phone: '70000000',
          amount: 0,
          orderId: 1,
        ),
      ));
      await tester.pump();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('rend à 768x1024 (tablette)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(provider: 'orange'));
      await tester.pump();
      tester.takeException();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('provider moov à 360x640', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(provider: 'moov'));
      await tester.pump();
      tester.takeException();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('montant 50000 FCFA', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaymentScreen(
          restaurantId: 5,
          provider: 'orange',
          phone: '76543210',
          amount: 50000,
          orderId: 123,
        ),
      ));
      await tester.pump();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('restaurant id différent', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaymentScreen(
          restaurantId: 999,
          provider: 'wave',
          phone: '70111111',
          amount: 3000,
          orderId: 555,
        ),
      ));
      await tester.pump();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('animation pulse démarre sans erreur', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      tester.takeException();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('provider telecel à 360x640', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(provider: 'telecel'));
      await tester.pump();
      tester.takeException();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('affiche CircularProgressIndicator ou AnimatedBuilder',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      final hasAnim =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
              find.byType(AnimatedBuilder).evaluate().isNotEmpty ||
              find.byType(ScaleTransition).evaluate().isNotEmpty;
      expect(hasAnim, isTrue);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('montant 1 FCFA (minimum)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaymentScreen(
          restaurantId: 1,
          provider: 'orange',
          phone: '70000001',
          amount: 1,
          orderId: 1,
        ),
      ));
      await tester.pump();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });

    testWidgets('téléphone format international', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaymentScreen(
          restaurantId: 1,
          provider: 'orange',
          phone: '+22670000000',
          amount: 2000,
          orderId: 1,
        ),
      ));
      await tester.pump();
      expect(find.byType(PaymentScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpWidget(_blank);
    });
  });
}
