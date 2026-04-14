import 'package:flutter/material.dart';

/// Constantes de design partagées dans toute l'application.
class AppDefaults {
  static const double radius = 12.0;
  static const double margin = 16.0;
  static const double padding = 16.0;

  /// Border radius standard (cartes, boutons)
  static BorderRadius get borderRadius => BorderRadius.circular(radius);

  /// Border radius Bottom Sheet
  static BorderRadius get bottomSheetRadius => const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      );

  /// Ombre légère standard pour les cartes
  static List<BoxShadow> get boxShadow => [
        BoxShadow(
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 3),
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ];

  /// Durée standard des animations
  static const Duration duration = Duration(milliseconds: 250);
}
