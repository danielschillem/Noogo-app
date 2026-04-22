import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/delivery.dart';
import 'driver_api_service.dart';
import 'driver_location_service.dart';

class DriverProvider extends ChangeNotifier {
  final DriverApiService _api = DriverApiService.instance;

  List<Delivery> _activeDeliveries = [];
  List<Delivery> _history = [];
  Delivery? _currentDelivery;
  bool _isLoading = false;
  bool _isOnline = false;
  String? _error;
  Timer? _pollTimer;

  List<Delivery> get activeDeliveries => _activeDeliveries;
  List<Delivery> get history => _history;
  Delivery? get currentDelivery => _currentDelivery;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get error => _error;

  /// Load active deliveries + start polling
  Future<void> loadActiveDeliveries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeDeliveries = await _api.getActiveDeliveries();
      // Auto-select current if only one active
      if (_activeDeliveries.length == 1) {
        _currentDelivery = _activeDeliveries.first;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ loadActiveDeliveries: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load delivery history
  Future<void> loadHistory() async {
    try {
      _history = await _api.getDeliveryHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadHistory: $e');
    }
  }

  /// Select a delivery to work on
  void selectDelivery(Delivery delivery) {
    _currentDelivery = delivery;
    notifyListeners();
  }

  /// Advance delivery to next status + start/stop GPS tracking
  Future<bool> advanceStatus() async {
    if (_currentDelivery == null) return false;
    final next = _currentDelivery!.nextStatus;
    if (next == null) return false;

    try {
      final updated =
          await _api.updateDeliveryStatus(_currentDelivery!.id, next);
      _currentDelivery = updated;

      // Update in list
      final idx = _activeDeliveries.indexWhere((d) => d.id == updated.id);
      if (idx >= 0) {
        if (updated.isCompleted || updated.isFailed) {
          _activeDeliveries.removeAt(idx);
        } else {
          _activeDeliveries[idx] = updated;
        }
      }

      // GPS tracking: start when picked_up or on_way, stop when delivered/failed
      if (updated.status == 'picked_up' || updated.status == 'on_way') {
        await DriverLocationService.instance.startTracking(updated.id);
      }
      if (updated.isCompleted || updated.isFailed) {
        await DriverLocationService.instance.stopTracking();
        _currentDelivery = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Mark delivery as failed
  Future<bool> markFailed() async {
    if (_currentDelivery == null) return false;

    try {
      final updated =
          await _api.updateDeliveryStatus(_currentDelivery!.id, 'failed');
      _currentDelivery = null;
      _activeDeliveries.removeWhere((d) => d.id == updated.id);
      await DriverLocationService.instance.stopTracking();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle online/offline
  Future<void> toggleOnline() async {
    final newStatus = _isOnline ? 'offline' : 'available';
    try {
      await _api.updateDriverStatus(newStatus);
      _isOnline = !_isOnline;
      if (_isOnline) {
        _startPolling();
      } else {
        _stopPolling();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ toggleOnline: $e');
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadActiveDeliveries();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    DriverLocationService.instance.stopTracking();
    super.dispose();
  }
}
