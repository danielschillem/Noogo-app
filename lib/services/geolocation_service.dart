import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_logger.dart';

/// Service de géolocalisation — FEAT-003
///
/// - Demande la permission de localisation (request au premier appel)
/// - Retourne la position courante de l'utilisateur
/// - Calcule la distance en km entre l'utilisateur et le restaurant
/// - Ouvre Google Maps / Plans avec l'adresse ou les coordonnées du restaurant
class GeolocationService {
  GeolocationService._();

  // ================================================================
  // PERMISSION & POSITION
  // ================================================================

  /// Retourne la position actuelle, ou null si refusée / indisponible.
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('GPS désactivé sur l\'appareil', tag: 'Geo');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Permission GPS refusée', tag: 'Geo');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Permission GPS refusée définitivement', tag: 'Geo');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // Économie batterie
          timeLimit: Duration(seconds: 10),
        ),
      );

      AppLogger.debug(
        'Position obtenue: ${position.latitude}, ${position.longitude}',
        tag: 'Geo',
      );

      return position;
    } catch (e) {
      AppLogger.error('Erreur géolocalisation', tag: 'Geo', error: e);
      return null;
    }
  }

  // ================================================================
  // DISTANCE
  // ================================================================

  /// Calcule la distance en km entre la position de l'utilisateur
  /// et les coordonnées du restaurant (Haversine).
  /// Retourne null si l'une ou l'autre sont absentes.
  static Future<double?> getDistanceToRestaurant({
    required double? restaurantLat,
    required double? restaurantLng,
  }) async {
    if (restaurantLat == null || restaurantLng == null) return null;

    final userPosition = await getCurrentPosition();
    if (userPosition == null) return null;

    final distanceMeters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      restaurantLat,
      restaurantLng,
    );

    return distanceMeters / 1000; // → km
  }

  /// Formate la distance en texte lisible.
  /// < 1 km → "850 m", >= 1 km → "1.2 km"
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  // ================================================================
  // ITINÉRAIRE (OUVRIR MAPS)
  // ================================================================

  /// Ouvre Google Maps (Android/Web) ou Plans (iOS) avec :
  /// - les coordonnées GPS du restaurant si disponibles
  /// - sinon l'adresse textuelle encodée
  static Future<bool> openMapsForRestaurant({
    double? lat,
    double? lng,
    required String address,
  }) async {
    Uri mapsUri;

    if (lat != null && lng != null) {
      // Coordonnées précises — Google Maps
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        mapsUri = Uri.parse('maps://?q=$lat,$lng');
      } else {
        mapsUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
      }
    } else {
      // Adresse textuelle — fallback
      final encoded = Uri.encodeComponent(address);
      mapsUri =
          Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    }

    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
        return true;
      }

      // Fallback web universel
      final fallback = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
      return true;
    } catch (e) {
      AppLogger.error('Impossible d\'ouvrir Maps', tag: 'Geo', error: e);
      return false;
    }
  }
}
