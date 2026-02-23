import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class QRHelper {
  static const String qrBaseUrl = 'https://dashboard-noogo.quickdev-it.com';
  static String generateRestaurantQRData(int restaurantId) {
    return '$qrBaseUrl/restaurant/$restaurantId/menu';
  }

  static bool isValidRestaurantQR(String qrData) {
    if (qrData.isEmpty) {
      if (kDebugMode) debugPrint('❌ QR vide');
      return false;
    }

    final isValidFormat = qrData.startsWith(qrBaseUrl) &&
        (qrData.contains('/restaurant/'));

    if (kDebugMode) {
      debugPrint('🔍 Validation QR:');
      debugPrint('   - QR scanné: $qrData');
      debugPrint('   - Base URL attendue: ${ApiConfig.baseUrl}');
      debugPrint('   - Valide: $isValidFormat');
    }
    debugPrint('   - Base URL attendue: $qrBaseUrl');
    return isValidFormat;
  }

  /// Parse l'ID du restaurant depuis le QR Code
  static int? parseRestaurantId(String qrData) {
    try {

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
    return '$qrBaseUrl/restaurant/$restaurantId/menu';
  }
}