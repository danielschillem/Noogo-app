import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/waiter_order.dart';
import 'waiter_api_service.dart';

class WaiterProvider extends ChangeNotifier {
  final WaiterApiService _api = WaiterApiService.instance;

  // ─── Restaurant context ────────────────────────────────────────────────────
  int? restaurantId;
  String? restaurantName;
  String? staffRole;

  // ─── Orders ────────────────────────────────────────────────────────────────
  List<WaiterOrder> _orders = [];
  bool _isLoading = false;
  String? _error;
  final String _filterStatus = 'active'; // 'active' | 'all' | specific status
  Timer? _pollTimer;

  List<WaiterOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterStatus => _filterStatus;

  List<WaiterOrder> get pendingOrders =>
      _orders.where((o) => o.status == 'pending').toList();
  List<WaiterOrder> get confirmedOrders =>
      _orders.where((o) => o.status == 'confirmed').toList();
  List<WaiterOrder> get preparingOrders =>
      _orders.where((o) => o.status == 'preparing').toList();
  List<WaiterOrder> get readyOrders =>
      _orders.where((o) => o.status == 'ready').toList();
  List<WaiterOrder> get activeOrders =>
      _orders.where((o) => o.isActive).toList();

  int get pendingCount => pendingOrders.length;
  int get readyCount => readyOrders.length;

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      final restaurant = await _api.getMyRestaurant();
      restaurantId = restaurant['id'] as int?;
      restaurantName = restaurant['nom']?.toString();
      staffRole = restaurant['role']?.toString();
      notifyListeners();
      await loadOrders();
      _startPolling();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ─── Orders loading ────────────────────────────────────────────────────────

  Future<void> loadOrders() async {
    if (restaurantId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _api.getOrders(restaurantId!);
      // Sort: ready first, then pending, then preparing, then confirmed, then closed
      _orders.sort((a, b) {
        final rank = {
          'ready': 0,
          'pending': 1,
          'confirmed': 2,
          'preparing': 3,
          'delivered': 4,
          'completed': 5,
          'cancelled': 6,
        };
        final ra = rank[a.status] ?? 9;
        final rb = rank[b.status] ?? 9;
        if (ra != rb) return ra.compareTo(rb);
        return b.createdAt.compareTo(a.createdAt);
      });
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ WaiterProvider.loadOrders: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => loadOrders());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<bool> updateStatus(WaiterOrder order, String newStatus) async {
    if (restaurantId == null) return false;
    try {
      final updated =
          await _api.updateOrderStatus(restaurantId!, order.id, newStatus);
      _replaceOrder(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelOrder(WaiterOrder order) async {
    if (restaurantId == null) return false;
    try {
      await _api.cancelOrder(restaurantId!, order.id);
      _replaceOrder(order.copyWith(status: 'cancelled'));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<WaiterOrder?> createOrder({
    required List<Map<String, dynamic>> items,
    required String orderType,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) async {
    if (restaurantId == null) return null;
    try {
      final created = await _api.createOrder(
        restaurantId: restaurantId!,
        items: items,
        orderType: orderType,
        tableNumber: tableNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        notes: notes,
      );
      _orders.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ─── Local update when Pusher event arrives ────────────────────────────────

  void onPusherOrderEvent(Map<String, dynamic> data) {
    final orderId = int.tryParse(data['order_id']?.toString() ?? '');
    final newStatus = data['status']?.toString();
    if (orderId == null || newStatus == null) return;

    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(status: newStatus);
    } else {
      // New order from another channel (e.g. client app) — reload
      loadOrders();
      return;
    }
    notifyListeners();
  }

  void addNewOrder(WaiterOrder order) {
    final existing = _orders.indexWhere((o) => o.id == order.id);
    if (existing < 0) {
      _orders.insert(0, order);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _replaceOrder(WaiterOrder updated) {
    final idx = _orders.indexWhere((o) => o.id == updated.id);
    if (idx >= 0) {
      _orders[idx] = updated;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
