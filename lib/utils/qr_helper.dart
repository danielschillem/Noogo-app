import 'package:flutter/foundation.dart';

class QRHelper {
  /// URLs acceptées comme sources de QR codes valides
  static const List<String> _validBaseUrls = [
    'https://noogo-e5ygx.ondigitalocean.app',
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

    // Accepter les formats URL connus et un ID direct.
    // Exemples:
    // - https://.../restaurant/{id}
    // - https://.../restaurants/{id}
    // - https://.../r/{id}[/login]
    // - {id}
    final uri = Uri.tryParse(qrData);
    if (uri != null && parseRestaurantId(qrData) != null) {
      if (kDebugMode) {
        debugPrint('🔍 Validation QR: valide (ID extrait depuis URL)');
        debugPrint('   - QR scanné: $qrData');
      }
      return true;
    }

    // Fallback: simple numéro = ID direct
    if (int.tryParse(qrData.trim()) != null) {
      if (kDebugMode) debugPrint('🔍 Validation QR: valide (ID direct)');
      return true;
    }

    // Vérification stricte avec liste d'URLs connues + extraction d'ID.
    final isValidFormat =
        _validBaseUrls.any((base) => qrData.startsWith(base)) &&
            parseRestaurantId(qrData) != null;

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

      // Formats principaux:
      // /restaurant/{id}, /restaurants/{id}, /r/{id}[/login]
      int? _idAfterSegment(String segmentName) {
        final index = segments.indexOf(segmentName);
        if (index != -1 && index + 1 < segments.length) {
          return int.tryParse(segments[index + 1]);
        }
        return null;
      }

      final id =
          _idAfterSegment('restaurant') ??
          _idAfterSegment('restaurants') ??
          _idAfterSegment('r');

      if (id != null && id > 0) {
        if (kDebugMode) debugPrint('   - ID extrait: $id');
        return id;
      }

      // Fallback query params (?restaurant_id=12, ?id=12)
      final fromQuery =
          int.tryParse(uri.queryParameters['restaurant_id'] ?? '') ??
          int.tryParse(uri.queryParameters['id'] ?? '');
      if (fromQuery != null && fromQuery > 0) {
        if (kDebugMode) debugPrint('   - ID extrait depuis query: $fromQuery');
        return fromQuery;
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
