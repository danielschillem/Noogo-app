import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noogo/widgets/qr_scanner_overlay.dart';

void main() {
  group('QrScannerOverlayShape — valeurs par défaut', () {
    const shape = QrScannerOverlayShape();

    test('borderColor par défaut est Colors.red', () {
      expect(shape.borderColor, Colors.red);
    });

    test('borderWidth par défaut est 0.5', () {
      expect(shape.borderWidth, 0.5);
    });

    test('cutOutSize par défaut est 200', () {
      expect(shape.cutOutSize, 200.0);
    });

    test('borderRadius par défaut est 0', () {
      expect(shape.borderRadius, 0.0);
    });

    test('borderLength par défaut est 30', () {
      expect(shape.borderLength, 30.0);
    });

    test('dimensions retourne EdgeInsets.all(10)', () {
      expect(shape.dimensions, const EdgeInsets.all(10));
    });
  });

  group('QrScannerOverlayShape — constructeur personnalisé', () {
    const shape = QrScannerOverlayShape(
      borderColor: Colors.green,
      borderWidth: 3.0,
      overlayColor: Color(0x80000000),
      borderRadius: 12.0,
      borderLength: 40.0,
      cutOutSize: 250.0,
    );

    test('borderColor personnalisé', () {
      expect(shape.borderColor, Colors.green);
    });

    test('borderWidth personnalisé', () {
      expect(shape.borderWidth, 3.0);
    });

    test('borderRadius personnalisé', () {
      expect(shape.borderRadius, 12.0);
    });

    test('cutOutSize personnalisé', () {
      expect(shape.cutOutSize, 250.0);
    });
  });

  group('QrScannerOverlayShape — méthodes Path', () {
    const shape = QrScannerOverlayShape(cutOutSize: 150);
    final rect = Rect.fromLTWH(0, 0, 400, 600);

    test('getOuterPath retourne un Path non nul', () {
      final path = shape.getOuterPath(rect);
      expect(path, isA<Path>());
    });

    test('getInnerPath retourne un Path non nul', () {
      final path = shape.getInnerPath(rect);
      expect(path, isA<Path>());
    });
  });

  group('QrScannerOverlayShape.scale', () {
    const shape = QrScannerOverlayShape(
      borderWidth: 2.0,
      borderRadius: 10.0,
      borderLength: 30.0,
      cutOutSize: 200.0,
    );

    test('scale(0.5) divise les dimensions par 2', () {
      final scaled = shape.scale(0.5) as QrScannerOverlayShape;
      expect(scaled.borderWidth, closeTo(1.0, 0.01));
      expect(scaled.cutOutSize, closeTo(100.0, 0.01));
    });

    test('scale(1.0) retourne valeurs identiques', () {
      final scaled = shape.scale(1.0) as QrScannerOverlayShape;
      expect(scaled.borderWidth, shape.borderWidth);
      expect(scaled.cutOutSize, shape.cutOutSize);
    });

    test('scale(2.0) double les dimensions', () {
      final scaled = shape.scale(2.0) as QrScannerOverlayShape;
      expect(scaled.borderWidth, closeTo(4.0, 0.01));
    });
  });

  group('QrScannerOverlayShape.lerpFrom', () {
    const shapeA = QrScannerOverlayShape(borderWidth: 1.0, cutOutSize: 100.0);
    const shapeB = QrScannerOverlayShape(borderWidth: 3.0, cutOutSize: 200.0);

    test('lerpFrom autre QrScannerOverlayShape à t=0.5', () {
      final lerped = shapeB.lerpFrom(shapeA, 0.5) as QrScannerOverlayShape?;
      expect(lerped, isNotNull);
      expect(lerped!.borderWidth, closeTo(2.0, 0.01));
      expect(lerped.cutOutSize, closeTo(150.0, 0.01));
    });

    test('lerpFrom null retourne une ShapeBorder (super)', () {
      final result = shapeB.lerpFrom(null, 0.5);
      // super.lerpFrom(null, 0.5) retourne une instance par défaut
      expect(result, isA<ShapeBorder>());
    });
  });

  group('QrScannerOverlayShape.lerpTo', () {
    const shapeA = QrScannerOverlayShape(borderWidth: 1.0, cutOutSize: 100.0);
    const shapeB = QrScannerOverlayShape(borderWidth: 3.0, cutOutSize: 200.0);

    test('lerpTo autre QrScannerOverlayShape à t=0.5', () {
      final lerped = shapeA.lerpTo(shapeB, 0.5) as QrScannerOverlayShape?;
      expect(lerped, isNotNull);
      expect(lerped!.borderWidth, closeTo(2.0, 0.01));
      expect(lerped.cutOutSize, closeTo(150.0, 0.01));
    });

    test('lerpTo null retourne une ShapeBorder (super)', () {
      final result = shapeA.lerpTo(null, 0.5);
      // super.lerpTo(null, 0.5) retourne une instance par défaut
      expect(result, isA<ShapeBorder>());
    });
  });

  group('QrScannerOverlayShape.paint (avec borderRadius)', () {
    testWidgets('paint avec borderRadius > 0 ne plante pas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 400,
              height: 600,
              decoration: const ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderRadius: 10,
                  borderWidth: 3,
                  cutOutSize: 200,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('paint sans borderRadius ne plante pas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 400,
              height: 600,
              decoration: const ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderRadius: 0,
                  borderWidth: 2,
                  cutOutSize: 150,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Container), findsOneWidget);
    });
  });
}
