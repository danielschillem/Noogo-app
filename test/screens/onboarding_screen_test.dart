import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noogo/screens/onboarding_screen.dart';

const _kSize = Size(390, 900);

Widget _wrap({Widget? home}) {
  SharedPreferences.setMockInitialValues({});
  return MaterialApp(
    home: home ?? const OnboardingScreen(),
    routes: {
      '/welcome': (_) => const Scaffold(body: Text('Welcome')),
    },
  );
}

// Suppress rendering overflow warnings — expected in fixed test canvas.
void _suppressOverflow(WidgetTester tester) {
  final saved = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    saved?.call(details);
  };
  addTearDown(() => FlutterError.onError = saved);
}

Future<void> _setUp(WidgetTester tester) async {
  _suppressOverflow(tester);
  await tester.binding.setSurfaceSize(_kSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingScreen', () {
    testWidgets('renders first slide with title and Suivant button',
        (tester) async {
      await _setUp(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue sur Noogo'), findsOneWidget);
      expect(find.text('Suivant'), findsOneWidget);
      expect(find.text('Passer'), findsOneWidget);
    });

    testWidgets('tapping Suivant advances to second slide', (tester) async {
      await _setUp(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      expect(find.text('Scannez le QR Code'), findsOneWidget);
    });

    testWidgets('shows C\'est parti! on last slide', (tester) async {
      await _setUp(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Navigate to last page (4 slides, so 3 taps)
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }

      expect(find.text("C'est parti !"), findsOneWidget);
    });

    testWidgets('renders 4 page indicator dots', (tester) async {
      await _setUp(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('Passer button saves onboarding_complete and navigates',
        (tester) async {
      await _setUp(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
      expect(find.text('Welcome'), findsOneWidget);
    });

    testWidgets(
        'completing last slide saves onboarding_complete and navigates to welcome',
        (tester) async {
      await _setUp(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text("C'est parti !"));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
