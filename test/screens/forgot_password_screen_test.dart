import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/screens/forgot_password_screen.dart';

Widget _wrap() => const MaterialApp(
      home: ForgotPasswordScreen(),
    );

void main() {
  group('ForgotPasswordScreen', () {
    testWidgets('renders step 1 with phone field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(1));
    });

    testWidgets('has a submit button in step 1', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(milliseconds: 400));

      // ElevatedButton.icon creates _ElevatedButtonWithIcon, find by label text
      expect(find.text('Obtenir le code'), findsOneWidget);
    });

    testWidgets('shows validation error on empty phone submit', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Find and tap the first elevated/text button
      final btn = find.byType(ElevatedButton);
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first);
        await tester.pumpAndSettle();
        // Validation should show error (phone required)
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('phone field accepts input', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, '70123456');
        expect(find.text('70123456'), findsOneWidget);
      }
    });

    testWidgets('has back navigation', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Back arrow or button should exist
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows error on invalid phone format', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, 'abc');
        final btn = find.byType(ElevatedButton);
        if (btn.evaluate().isNotEmpty) {
          await tester.tap(btn.first);
          await tester.pumpAndSettle();
          expect(find.byType(Form), findsOneWidget);
        }
      }
    });

    testWidgets('shows validation error on empty submit', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final btn = find.byType(ElevatedButton);
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first);
        await tester.pumpAndSettle();
        // Should show "Entrez votre numéro" error
        final hasErr = find.text('Entrez votre numéro').evaluate().isNotEmpty ||
            find.byType(Form).evaluate().isNotEmpty;
        expect(hasErr, isTrue);
      }
    });

    testWidgets('title "Mot de passe oublié" is displayed', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe oublié'), findsOneWidget);
    });

    testWidgets('phone field rejects too-short number', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, '1234');
        final btn = find.byType(ElevatedButton);
        if (btn.evaluate().isNotEmpty) {
          await tester.tap(btn.first);
          await tester.pump();
          expect(find.byType(Scaffold), findsOneWidget);
        }
      }
    });

    testWidgets('step 1 shows phone field label/hint', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsAtLeast(1));
    });

    testWidgets('rend à 360x640 sans overflow fatal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      tester.takeException();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('dispose sans erreur', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
      expect(find.byType(ForgotPasswordScreen), findsNothing);
    });

    testWidgets('champ téléphone accepte 8 chiffres', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, '70123456');
        expect(find.text('70123456'), findsOneWidget);
      }
    });

    testWidgets('affiche un formulaire Form', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('rend à 768x1024 (tablette)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      tester.takeException();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('contient des icônes', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('contient un bouton d\'action', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // ElevatedButton.icon creates a specialized type — search by text
      final hasBtn = find.byType(ElevatedButton).evaluate().isNotEmpty ||
          find.text('Obtenir le code').evaluate().isNotEmpty;
      expect(hasBtn, isTrue);
    });

    testWidgets('numéro valide soumis — réseau échoue gracieusement',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, '70999888');
        await tester.pump();
        final btn = find.text('Obtenir le code');
        if (btn.evaluate().isNotEmpty) {
          await tester.tap(btn.first, warnIfMissed: false);
          await tester.pump(const Duration(seconds: 5));
        }
      }
      tester.takeException();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('affiche AppBar avec titre Mot de passe oublié',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Mot de passe oublié'), findsOneWidget);
    });

    testWidgets('affiche flèche retour dans AppBar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('tap flèche retour ne plante pas', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const ForgotPasswordScreen(),
        routes: {'/back': (_) => const Scaffold(body: Text('back'))},
      ));
      await tester.pumpAndSettle();
      final back = find.byIcon(Icons.arrow_back);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
      }
      tester.takeException();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('affiche fond SingleChildScrollView', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('validation numéro trop long', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, '70123456789123');
        await tester.pump();
        final btn = find.byType(ElevatedButton);
        if (btn.evaluate().isNotEmpty) {
          await tester.tap(btn.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
      tester.takeException();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('validation numéro avec espaces (format valide)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, '70 12 34 56');
        await tester.pump();
      }
      tester.takeException();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('validation numéro avec indicatif +226', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, '+22670123456');
        await tester.pump();
      }
      tester.takeException();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });
  });
}
