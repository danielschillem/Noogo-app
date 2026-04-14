import 'package:flutter/material.dart';

/// Classe pour créer l'overlay du scanner QR avec un cadre de découpe
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 0.5,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.8),
    this.borderRadius = 0,
    this.borderLength = 30,
    this.cutOutSize = 200,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect, textDirection: textDirection), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final Path path = Path()..addRect(rect);
    final Path cutOutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, path, cutOutPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mSize = cutOutSize + borderOffset * 2;
    final mAreaStartX = ((width - mSize) / 2);
    final mAreaStartY = ((height - mSize) / 2);

    // Dessiner l'overlay semi-transparent
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect, textDirection: textDirection), paint);

    // Dessiner les coins du cadre
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Coin supérieur gauche
    path.moveTo(mAreaStartX, mAreaStartY + borderLength);
    path.lineTo(mAreaStartX, mAreaStartY + borderRadius);
    if (borderRadius > 0) {
      path.arcToPoint(
        Offset(mAreaStartX + borderRadius, mAreaStartY),
        radius: Radius.circular(borderRadius),
      );
    } else {
      path.lineTo(mAreaStartX, mAreaStartY);
    }
    path.lineTo(mAreaStartX + borderLength, mAreaStartY);

    // Coin supérieur droit
    path.moveTo(mAreaStartX + mSize - borderLength, mAreaStartY);
    path.lineTo(mAreaStartX + mSize - borderRadius, mAreaStartY);
    if (borderRadius > 0) {
      path.arcToPoint(
        Offset(mAreaStartX + mSize, mAreaStartY + borderRadius),
        radius: Radius.circular(borderRadius),
      );
    } else {
      path.lineTo(mAreaStartX + mSize, mAreaStartY);
    }
    path.lineTo(mAreaStartX + mSize, mAreaStartY + borderLength);

    // Coin inférieur droit
    path.moveTo(mAreaStartX + mSize, mAreaStartY + mSize - borderLength);
    path.lineTo(mAreaStartX + mSize, mAreaStartY + mSize - borderRadius);
    if (borderRadius > 0) {
      path.arcToPoint(
        Offset(mAreaStartX + mSize - borderRadius, mAreaStartY + mSize),
        radius: Radius.circular(borderRadius),
      );
    } else {
      path.lineTo(mAreaStartX + mSize, mAreaStartY + mSize);
    }
    path.lineTo(mAreaStartX + mSize - borderLength, mAreaStartY + mSize);

    // Coin inférieur gauche
    path.moveTo(mAreaStartX + borderLength, mAreaStartY + mSize);
    path.lineTo(mAreaStartX + borderRadius, mAreaStartY + mSize);
    if (borderRadius > 0) {
      path.arcToPoint(
        Offset(mAreaStartX, mAreaStartY + mSize - borderRadius),
        radius: Radius.circular(borderRadius),
      );
    } else {
      path.lineTo(mAreaStartX, mAreaStartY + mSize);
    }
    path.lineTo(mAreaStartX, mAreaStartY + mSize - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is QrScannerOverlayShape) {
      return QrScannerOverlayShape(
        borderColor: Color.lerp(a.borderColor, borderColor, t)!,
        borderWidth: a.borderWidth + (borderWidth - a.borderWidth) * t,
        overlayColor: Color.lerp(a.overlayColor, overlayColor, t)!,
        borderRadius: a.borderRadius + (borderRadius - a.borderRadius) * t,
        borderLength: a.borderLength + (borderLength - a.borderLength) * t,
        cutOutSize: a.cutOutSize + (cutOutSize - a.cutOutSize) * t,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is QrScannerOverlayShape) {
      return QrScannerOverlayShape(
        borderColor: Color.lerp(borderColor, b.borderColor, t)!,
        borderWidth: borderWidth + (b.borderWidth - borderWidth) * t,
        overlayColor: Color.lerp(overlayColor, b.overlayColor, t)!,
        borderRadius: borderRadius + (b.borderRadius - borderRadius) * t,
        borderLength: borderLength + (b.borderLength - borderLength) * t,
        cutOutSize: cutOutSize + (b.cutOutSize - cutOutSize) * t,
      );
    }
    return super.lerpTo(b, t);
  }
}