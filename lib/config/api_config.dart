import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  // ============================================
  // 🔐 CONFIGURATION DEPUIS .env
  // ============================================
  
  /// Base URL de l'API
  static String get baseUrl => 
      dotenv.env['API_BASE_URL'] ?? 'https://dashboard-noogo.quickdev-it.com/api';

  /// Base URL pour les images
  static String get imageBaseUrl => 
      dotenv.env['IMAGE_BASE_URL'] ?? 'https://dashboard-noogo.quickdev-it.com';

  /// Base URL pour les QR codes
  static String get qrBaseUrl => 
      dotenv.env['QR_BASE_URL'] ?? 'https://dashboard-noogo.quickdev-it.com';

  // ============================================
  // 🔌 CONFIGURATION PUSHER
  // ============================================
  
  /// Clé API Pusher
  static String get pusherKey => 
      dotenv.env['PUSHER_APP_KEY'] ?? '';

  /// Cluster Pusher
  static String get pusherCluster => 
      dotenv.env['PUSHER_CLUSTER'] ?? 'eu';

  /// App ID Pusher
  static String get pusherAppId => 
      dotenv.env['PUSHER_APP_ID'] ?? '';

  /// Endpoint d'authentification Pusher
  static String get pusherAuthEndpoint => 
      dotenv.env['PUSHER_AUTH_ENDPOINT'] ?? '$baseUrl/broadcasting/auth';

  // ============================================
  // 🛠️ CONFIGURATION ENVIRONNEMENT
  // ============================================
  
  /// Mode debug actif
  static bool get isDebugMode => 
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true' || kDebugMode;

  /// Environnement actuel (development, staging, production)
  static String get environment => 
      dotenv.env['ENVIRONMENT'] ?? 'development';

  /// Vérifie si en production
  static bool get isProduction => environment == 'production';

  // ============================================
  // 🖼️ CONFIGURATION IMAGES
  // ============================================

  /// Image de remplacement par défaut
  static const String defaultImageUrl =
      'https://via.placeholder.com/400x300/CCCCCC/666666?text=Restaurant+Image';

  static final Map<String, bool> _urlValidationCache = {};

  // ✅ Construit une URL complète d'image avec gestion storage Laravel
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      if (kDebugMode) debugPrint('⚠️ ImagePath vide ou null');
      return defaultImageUrl;
    }

    String cleanPath = imagePath.trim();

    // Si déjà une URL complète (http/https)
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      if (kDebugMode) debugPrint('✅ URL complète détectée: $cleanPath');
      return cleanPath;
    }

    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

// ✅ CORRECTION : Gérer tous les types de chemins
    if (!cleanPath.startsWith('storage/')) {
      // ✅ Catégories
      if (cleanPath.startsWith('categories/')) {
        cleanPath = 'storage/$cleanPath';
      }
      // ✅ Restaurants
      else if (cleanPath.startsWith('restaurants/')) {
        cleanPath = 'storage/$cleanPath';
      }
      // ✅ Plats
      else if (cleanPath.startsWith('plats/') || cleanPath.startsWith('dishes/')) {
        cleanPath = 'storage/$cleanPath';
      }
      // ✅ Images génériques
      else if (cleanPath.startsWith('images/') || cleanPath.startsWith('uploads/')) {
        cleanPath = 'storage/$cleanPath';
      }
      // ✅ Contient un slash mais non reconnu
      else if (cleanPath.contains('/')) {
        cleanPath = 'storage/$cleanPath';
      }
      // ✅ Juste un nom de fichier
      else {
        cleanPath = 'storage/images/$cleanPath';
      }
    }

// Construire l'URL finale
    final fullUrl = '$imageBaseUrl/$cleanPath';

    if (kDebugMode) {
      debugPrint('🖼️ Chemin original: $imagePath');
      debugPrint('🖼️ Chemin nettoyé: $cleanPath');
      debugPrint('🖼️ URL finale: $fullUrl');
    }

    return fullUrl;
  }

  // ✅ Version sécurisée avec vérification de validité
  static String getSafeImageUrl(String? imagePath) {
    try {
      final url = getFullImageUrl(imagePath);
      return _isLikelyValidImageUrl(url) ? url : defaultImageUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la construction de l\'URL d\'image: $e');
      }
      return defaultImageUrl;
    }
  }

  // ✅ Vérifie que l'URL ressemble à une URL valide
  static bool _isLikelyValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  // ✅ Vérifie si une image est accessible sur le serveur
  static Future<bool> checkImageAccessibility(String url) async {
    if (_urlValidationCache.containsKey(url)) {
      return _urlValidationCache[url]!;
    }

    try {
      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
      );

      final isAccessible = response.statusCode == 200;
      _urlValidationCache[url] = isAccessible;

      if (kDebugMode) {
        debugPrint('🔍 Vérification image: $url');
        debugPrint('   - Status: ${response.statusCode}');
        debugPrint('   - Accessible: $isAccessible');
      }

      return isAccessible;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur vérification image: $url');
        debugPrint('   - Erreur: $e');
      }
      _urlValidationCache[url] = false;
      return false;
    }
  }

  // ✅ Construit une URL d'API à partir d'un endpoint
  static String getApiUrl(String endpoint) {
    final cleanEndpoint =
    endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$baseUrl/$cleanEndpoint';
  }

  /// URL de base pour l'authentification
  static String get authBaseUrl => '$baseUrl/auth';

  // ✅ Vérifie si l'API est joignable
  static Future<bool> checkApiConnection() async {
    try {
      final uri = Uri.parse(baseUrl);
      final response = await http.head(uri).timeout(
        const Duration(seconds: 10),
      );

      if (kDebugMode) {
        debugPrint('🔍 Vérification connexion API: $uri');
        debugPrint('   - Status: ${response.statusCode}');
      }

      return response.statusCode < 500;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur de connexion API: $e');
      }
      return false;
    }
  }

  // ✅ Efface le cache de validation
  static void clearValidationCache() {
    _urlValidationCache.clear();
    if (kDebugMode) {
      debugPrint('🗑️ Cache de validation des URLs effacé');
    }
  }
}