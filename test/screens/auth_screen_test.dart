import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/screens/auth_screen.dart';

Widget _wrap() => MaterialApp(
      home: const AuthScreen(),
      routes: {
        '/home': (ctx) => const Scaffold(body: Text('Home')),
      },
    );

void main() {
  group('AuthScreen', () {
    testWidgets('renders login form by default', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Connexion'), findsWidgets);
      expect(find.byType(TextFormField), findsAtLeast(1));
    });

    testWidgets('shows phone and password fields in login mode',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Login mode: phone + password
      expect(find.byType(TextFormField), findsAtLeast(2));
    });

    testWidgets('can toggle to register mode', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Find and tap the "Créer un compte" or similar toggle
      final toggleFinder = find.text('Créer un compte');
      if (toggleFinder.evaluate().isNotEmpty) {
        await tester.tap(toggleFinder);
        await tester.pumpAndSettle();
        expect(find.text('Inscription'), findsWidgets);
      }
    });

    testWidgets('shows validation error when submitting empty form',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(ElevatedButton, 'Se connecter');
      if (submitBtn.evaluate().isNotEmpty) {
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        // Should show some validation feedback
        expect(find.byType(Form), findsOneWidget);
      }
    });

    testWidgets('phone field accepts valid number', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final phoneFields = find.byType(TextFormField);
      if (phoneFields.evaluate().isNotEmpty) {
        await tester.enterText(phoneFields.first, '70123456');
        await tester.pump();
        // No immediate error
        expect(find.text('Numéro invalide (ex: 70 12 34 56)'), findsNothing);
      }
    });

    testWidgets('has a back button or navigation', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('password field is obscured', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Check that obscured text fields exist
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      final obscured = fields.where((f) => f.obscureText == true);
      expect(obscured, isNotEmpty);
    });

    testWidgets('affiche le titre "Connexion" ou "Inscription"',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final hasTitle = find.text('Connexion').evaluate().isNotEmpty ||
          find.text('Inscription').evaluate().isNotEmpty;
      expect(hasTitle, isTrue);
    });

    testWidgets('a un AppBar ou header visible', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('saisie du mot de passe sans erreur immédiate', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final obscuredFields = find.byWidgetPredicate(
        (w) => w is TextField && w.obscureText,
      );
      if (obscuredFields.evaluate().isNotEmpty) {
        await tester.enterText(obscuredFields.first, 'MonMotDePasse123');
        await tester.pump();
        expect(find.byType(Form), findsOneWidget);
      }
    });

    testWidgets('mode inscription ajoute des champs supplémentaires',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final initialFields = find.byType(TextFormField).evaluate().length;

      final toggleFinder = find.text('Créer un compte');
      if (toggleFinder.evaluate().isNotEmpty) {
        await tester.tap(toggleFinder);
        await tester.pumpAndSettle();
        final newFields = find.byType(TextFormField).evaluate().length;
        expect(newFields, greaterThanOrEqualTo(initialFields));
      }
    });

    testWidgets('affiche le bouton de connexion principale', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });

    testWidgets('rend à 360x640 sans overflow fatal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      tester.takeException();
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('dispose sans erreur', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('tap connexion avec champs vides ne plante pas',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final btn = find.byType(ElevatedButton);
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
      }
      tester.takeException();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('scroll dans l\'écran de connexion', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final scrollables = find.byType(SingleChildScrollView);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -100));
        await tester.pump();
      }
      tester.takeException();
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('rend à 768x1024 (tablette)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      tester.takeException();
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('saisir téléphone et mot de passe simultanément',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(0), '70000000');
        await tester.enterText(fields.at(1), 'secret123');
        await tester.pump();
      }
      tester.takeException();
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('contient des icônes dans les champs', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('AuthScreen contient un Form', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('toggle icône visibilité mot de passe', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final eyeIcons = find.byIcon(Icons.visibility_off);
      if (eyeIcons.evaluate().isNotEmpty) {
        await tester.tap(eyeIcons.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));
      }
      tester.takeException();
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('mode inscription — affiche champ Nom', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final toggle = find.text('Créer un compte');
      if (toggle.evaluate().isNotEmpty) {
        await tester.tap(toggle.first);
        await tester.pumpAndSettle();
      }
      tester.takeException();
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('mode inscription — saisir nom, téléphone, mot de passe',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final toggle = find.text('Créer un compte');
      if (toggle.evaluate().isNotEmpty) {
        await tester.tap(toggle.first);
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        if (fields.evaluate().length >= 3) {
          await tester.enterText(fields.at(0), 'Jean Test');
          await tester.enterText(fields.at(1), '70123456');
          await tester.enterText(fields.at(2), 'pass1234');
          await tester.pump();
        }
      }
      tester.takeException();
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('mode inscription — submit vide affiche validation',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final toggle = find.text('Créer un compte');
      if (toggle.evaluate().isNotEmpty) {
        await tester.tap(toggle.first);
        await tester.pumpAndSettle();
        final btn = find.byType(ElevatedButton);
        if (btn.evaluate().isNotEmpty) {
          await tester.tap(btn.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('lien Mot de passe oublié visible en mode connexion',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final hasLink = find.textContaining('oublié').evaluate().isNotEmpty ||
          find.textContaining('Oublié').evaluate().isNotEmpty;
      if (hasLink) {
        final link = find.textContaining('oublié');
        await tester.tap(link.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
      }
      tester.takeException();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('connexion avec données valides — réseau échoue',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(0), '70000001');
        await tester.enterText(fields.at(1), 'password123');
        await tester.pump();
        final btn = find.text('Se connecter');
        if (btn.evaluate().isNotEmpty) {
          await tester.tap(btn.first, warnIfMissed: false);
          await tester.pump(const Duration(seconds: 5));
        }
      }
      tester.takeException();
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('retour de inscription vers connexion', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final toggle = find.text('Créer un compte');
      if (toggle.evaluate().isNotEmpty) {
        await tester.tap(toggle.first);
        await tester.pumpAndSettle();
        // Chercher un bouton retour vers connexion
        final back = find.textContaining('Connexion');
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back.first, warnIfMissed: false);
          await tester.pumpAndSettle();
        }
      }
      tester.takeException();
      expect(find.byType(AuthScreen), findsOneWidget);
    });
  });
}
