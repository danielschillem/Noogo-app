import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';
import '../utils/app_logger.dart';

/// Position GPS du livreur reçue via Pusher
class DriverLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  DriverLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Événement statut livraison reçu via Pusher
class DeliveryStatusEvent {
  final String status;
  final String? driverName;
  final DateTime timestamp;

  DeliveryStatusEvent({
    required this.status,
    this.driverName,
    required this.timestamp,
  });

  factory DeliveryStatusEvent.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusEvent(
      status: json['status']?.toString() ?? '',
      driverName: json['driver_name']?.toString(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Service de tracking de livraison en temps réel
///
/// - Souscrit au canal Pusher `delivery.{orderId}`
/// - Écoute `driver.location` → stream [driverLocationStream]
/// - Écoute `delivery.status` → stream [deliveryStatusStream]
/// - Permet de partager la position GPS du client vers le backend
class DeliveryTrackingService {
  static final DeliveryTrackingService _instance =
      DeliveryTrackingService._internal();
  factory DeliveryTrackingService() => _instance;
  DeliveryTrackingService._internal();

  PusherChannelsFlutter? _pusher;
  String? _currentChannelName;
  String? _authToken;

  final StreamController<DriverLocation> _locationController =
      StreamController<DriverLocation>.broadcast();
  final StreamController<DeliveryStatusEvent> _statusController =
      StreamController<DeliveryStatusEvent>.broadcast();

  Stream<DriverLocation> get driverLocationStream => _locationController.stream;
  Stream<DeliveryStatusEvent> get deliveryStatusStream =>
      _statusController.stream;

  bool get isSubscribed => _currentChannelName != null;

  /// Démarre le tracking d'une livraison
  Future<void> startTracking(int orderId, {String? authToken}) async {
    _authToken = authToken;
    final channelName = 'delivery.$orderId';

    if (_currentChannelName == channelName) return; // déjà abonné

    await stopTracking(); // nettoyer l'abonnement précédent

    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: _handleEvent,
      );
      _currentChannelName = channelName;
      AppLogger.info('DeliveryTracking: abonné à $channelName');
    } catch (e) {
      AppLogger.error('DeliveryTracking: erreur abonnement', error: e);
    }
  }

  /// Arrête le tracking
  Future<void> stopTracking() async {
    if (_currentChannelName != null && _pusher != null) {
      try {
        await _pusher!.unsubscribe(channelName: _currentChannelName!);
      } catch (_) {}
      _currentChannelName = null;
    }
  }

  void _handleEvent(PusherEvent event) {
    try {
      final data = jsonDecode(event.data ?? '{}') as Map<String, dynamic>;
      switch (event.eventName) {
        case 'driver.location':
          final loc = DriverLocation.fromJson(data);
          _locationController.add(loc);
          break;
        case 'delivery.status':
          final status = DeliveryStatusEvent.fromJson(data);
          _statusController.add(status);
          break;
        default:
          break;
      }
    } catch (e) {
      AppLogger.error('DeliveryTracking: erreur parsing event', error: e);
    }
  }

  /// Envoie la position GPS du client au backend
  /// POST /api/deliveries/{deliveryId}/client-location
  Future<void> sendClientLocation(int deliveryId, LatLng position) async {
    if (_authToken == null) return;
    try {
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/deliveries/$deliveryId/client-location');
      await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        AppLogger.warning('DeliveryTracking: envoi position client échoué');
      }
    }
  }

  /// Calcule la distance en km entre deux points (Haversine)
  static double distanceKm(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, from, to);
  }

  /// ETA estimé en minutes basé sur la distance (vitesse 20km/h en ville)
  static int etaMinutes(LatLng driverPos, LatLng clientPos) {
    final km = distanceKm(driverPos, clientPos);
    return (km / 20.0 * 60).ceil(); // 20 km/h moyenne en ville BF
  }

  /// Demande les permissions de localisation
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Obtient la position GPS actuelle
  static Future<LatLng?> getCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      AppLogger.error('DeliveryTracking: impossible d\'obtenir la position',
          error: e);
      return null;
    }
  }

  void dispose() {
    stopTracking();
    _locationController.close();
    _statusController.close();
  }
}
