import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'driver_api_service.dart';

/// Pushes driver GPS to backend every [intervalSeconds] while active.
class DriverLocationService {
  DriverLocationService._();
  static final DriverLocationService instance = DriverLocationService._();
  factory DriverLocationService() => instance;

  Timer? _timer;
  int? _activeDeliveryId;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  /// Start sending GPS for a specific delivery
  Future<void> startTracking(int deliveryId, {int intervalSeconds = 10}) async {
    await stopTracking();
    _activeDeliveryId = deliveryId;
    _isTracking = true;

    // Send immediately
    await _sendLocation();

    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      _sendLocation();
    });

    debugPrint('📍 GPS tracking started for delivery #$deliveryId');
  }

  /// Stop sending GPS
  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    _activeDeliveryId = null;
    _isTracking = false;
    debugPrint('📍 GPS tracking stopped');
  }

  Future<void> _sendLocation() async {
    if (_activeDeliveryId == null) return;

    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).timeout(const Duration(seconds: 10));

      await DriverApiService.instance.sendDriverLocation(
        _activeDeliveryId!,
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      debugPrint('⚠️ GPS send error: $e');
    }
  }

  Future<bool> _checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// Get current position once
  static Future<Position?> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('⚠️ getCurrentPosition error: $e');
      return null;
    }
  }
}
