import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:noogo/screens/qr_scanner_screen.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget _wrap() {
  return const MaterialApp(home: QRScannerScreen());
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

  group('QRScannerScreen', () {
    testWidgets('se construit sans erreur', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(QRScannerScreen), findsOneWidget);
    });

    testWidgets('affiche un Scaffold', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('affiche le titre "Scanner QR Code"', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Scanner QR Code'), findsOneWidget);
    });

    testWidgets('affiche l\'AppBar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('affiche le bouton torche (flash_off)', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    });

    testWidgets('affiche le bouton switch caméra (camera_rear)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.camera_rear), findsOneWidget);
    });

    testWidgets('affiche le message "Pointez la caméra"', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Pointez la caméra vers un QR code'), findsOneWidget);
    });

    testWidgets('affiche l\'icône qr_code_scanner', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    testWidgets('affiche un bouton de confirmation', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(IconButton), findsWidgets);
    });
  });
}
