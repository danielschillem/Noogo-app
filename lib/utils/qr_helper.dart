import 'package:flutter/foundation.dart';

class QRHelper {
  /// URLs acceptées comme sources de QR codes valides
  static const List<String> _validBaseUrls = [
    'https://noogo-app.netlify.app',
    'https://dashboard-noogo.quickdev-it.com',
    'http://localhost',
    'http://127.0.0.1',
  ];

  static String generateRestaurantQRData(int restaurantId) {
    return '${_validBaseUrls.first}/restaurant/$restaurantId';
  }

  static bool isValidRestaurantQR(String qrData) {
    if (qrData.isEmpty) {
      if (kDebugMode) debugPrint('❌ QR vide');
      return false;
    }

    // Accepter toute URL contenant /restaurant/{id}
    // ou un simple ID numérique
    final uri = Uri.tryParse(qrData);
    if (uri != null && qrData.contains('/restaurant/')) {
      if (kDebugMode) {
        debugPrint('🔍 Validation QR: valide (contient /restaurant/)');
        debugPrint('   - QR scanné: $qrData');
      }
      return true;
    }

    // Fallback: simple numéro = ID direct
    if (int.tryParse(qrData.trim()) != null) {
      if (kDebugMode) debugPrint('🔍 Validation QR: valide (ID direct)');
      return true;
    }

    // Vérification stricte avec liste d'URLs connues
    final isValidFormat =
        _validBaseUrls.any((base) => qrData.startsWith(base)) &&
            qrData.contains('/restaurant/');

    if (kDebugMode) {
      debugPrint('🔍 Validation QR:');
      debugPrint('   - QR scanné: $qrData');
      debugPrint('   - Valide: $isValidFormat');
    }
    return isValidFormat;
  }

  /// Parse l'ID du restaurant depuis le QR Code
  static int? parseRestaurantId(String qrData) {
    try {
      // Fallback: si c'est un simple numéro, c'est un ID direct
      final directId = int.tryParse(qrData.trim());
      if (directId != null) {
        if (kDebugMode) {
          debugPrint('🔍 Parse Restaurant ID: ID direct = $directId');
        }
        return directId;
      }

      final uri = Uri.parse(qrData);
      final segments = uri.pathSegments;

      if (kDebugMode) {
        debugPrint('🔍 Parse Restaurant ID:');
        debugPrint('   - URL: $qrData');
        debugPrint('   - Segments: $segments');
      }

      // Chercher "restaurant" dans les segments
      final restaurantIndex = segments.indexOf('restaurant');

      if (restaurantIndex != -1 && restaurantIndex + 1 < segments.length) {
        final id = int.tryParse(segments[restaurantIndex + 1]);
        if (kDebugMode) debugPrint('   - ID extrait: $id');
        return id;
      }

      if (kDebugMode) debugPrint('   - ❌ Format invalide');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur parse: $e');
      return null;
    }
  }

  /// Valide et extrait l'ID en une seule étape
  static int? validateAndExtractId(String qrData) {
    if (!isValidRestaurantQR(qrData)) {
      return null;
    }
    return parseRestaurantId(qrData);
  }

  /// Construit l'URL complète du menu à partir d'un ID
  static String getMenuUrl(int restaurantId) {
    return '${_validBaseUrls.first}/restaurant/$restaurantId';
  }
}
